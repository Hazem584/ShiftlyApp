import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { decodeIconPng,encodeRgb,resizeRgb } from './icon-png.ts';

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const hash=bytes=>createHash('sha256').update(bytes).digest('hex');
const write=async(file,body)=>{const full=path.join(root,file);await fs.mkdir(path.dirname(full),{recursive:true});await fs.writeFile(full,body);};
async function fetchBounded(url,max=1048576){
 const res=await fetch(url,{signal:AbortSignal.timeout(15000),redirect:'error'});
 if(!res.ok)throw new Error(`Icon endpoint returned HTTP ${res.status}`);
 const chunks=[];let length=0;for await(const chunk of res.body){length+=chunk.length;if(length>max)throw new Error('Icon response too large');chunks.push(chunk);}return Buffer.concat(chunks);
}
export async function prepare({baseUrl,catalogFile,projectRoot=root}={}){
 if(projectRoot!==root)throw new Error('Run this script in the application project');
 let catalog;
 if(catalogFile)catalog=JSON.parse(await fs.readFile(catalogFile,'utf8'));
 else {
  const base=new URL(baseUrl);
  if(base.protocol!=='https:'&&!(base.protocol==='http:'&&['localhost','127.0.0.1','10.0.2.2'].includes(base.hostname)))throw new Error('Use HTTPS for the icon backend');
  if(base.username||base.password||base.search||base.hash||!base.pathname.replace(/\/$/,'').endsWith('/api/v1'))throw new Error('Invalid backend base URL');
  baseUrl=base.toString().replace(/\/$/,'');
  catalog=JSON.parse((await fetchBounded(baseUrl+'/platform/app-icons/catalog',65536)).toString('utf8'));
 }
 if(!Array.isArray(catalog.icons)||catalog.icons.length>12)throw new Error('Invalid icon catalog');
 const cached=JSON.parse(await fs.readFile(path.join(root,'assets/app_icons/catalog.json'),'utf8'));
 const all=new Map(cached.icons.map(i=>[i.key,i]));
 for(const icon of catalog.icons){
  if(!/^[a-f0-9]{64}$/.test(icon.sha256)||icon.key!=='icon_'+icon.sha256||icon.imagePath!=='/platform/app-icons/images/'+icon.sha256+'.png')throw new Error('Invalid icon catalog reference');
  let bytes;
  const cachePath='assets/app_icons/'+icon.sha256+'.png';
  try{bytes=await fs.readFile(path.join(root,cachePath));if(hash(bytes)!==icon.sha256)bytes=null;}catch{}
  if(!bytes){if(!baseUrl)throw new Error('Offline generation requires previously downloaded icon PNG files');bytes=await fetchBounded(baseUrl+icon.imagePath);}
  if(hash(bytes)!==icon.sha256)throw new Error('Icon digest mismatch');
  decodeIconPng(bytes);await write(cachePath,bytes);all.set(icon.key,{key:icon.key,sha256:icon.sha256,name:String(icon.name).slice(0,80)});
 }
 // Never drop an icon already shipped in a build: devices may still have its alias enabled.
 if(all.size>12)throw new Error('At most 12 alternate icons can be packaged');
 const icons=[...all.values()].sort((a,b)=>a.key.localeCompare(b.key));
 const iosTemplate=JSON.parse(await fs.readFile(path.join(root,'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json'),'utf8'));
 for(const icon of icons){
  if(icon.key!=='icon_'+icon.sha256||!/^[a-f0-9]{64}$/.test(icon.sha256))throw new Error('Invalid cached icon key');
  const bytes=await fs.readFile(path.join(root,'assets/app_icons/'+icon.sha256+'.png'));if(hash(bytes)!==icon.sha256)throw new Error('Cached icon digest mismatch');
  const rgb=decodeIconPng(bytes);
  await write('android/app/src/main/res/drawable-nodpi/shiftly_'+icon.key+'.png',bytes);
  const images=[];
  for(const entry of iosTemplate.images){const size=Math.round(Number(entry.size.split('x')[0])*Number(entry.scale?.replace('x','')??1));const filename=`icon-${size}-${entry.idiom}.png`;await write(`ios/Runner/Assets.xcassets/Shiftly_${icon.key}.appiconset/${filename}`,encodeRgb(size,size,resizeRgb(rgb,size)));images.push({...entry,filename});}
  await write(`ios/Runner/Assets.xcassets/Shiftly_${icon.key}.appiconset/Contents.json`,JSON.stringify({images,info:{version:1,author:'xcode'}},null,2));
 }
 const manifestFile='android/app/src/main/AndroidManifest.xml';let manifest=await fs.readFile(path.join(root,manifestFile),'utf8');
 const aliases=icons.map(i=>`        <activity-alias android:name=".Launcher_${i.key}" android:targetActivity=".MainActivity" android:enabled="false" android:exported="true" android:icon="@drawable/shiftly_${i.key}"><meta-data android:name="shiftly.iconKey" android:value="${i.key}"/><meta-data android:name="shiftly.iconSha256" android:value="${i.sha256}"/><intent-filter><action android:name="android.intent.action.MAIN"/><category android:name="android.intent.category.LAUNCHER"/></intent-filter></activity-alias>`).join('\n');
 if(!manifest.includes('<!-- SHIFTLY_ALTERNATE_ICONS_START -->'))throw new Error('Missing Android icon generation markers');
 manifest=manifest.replace(/<!-- SHIFTLY_ALTERNATE_ICONS_START -->[\s\S]*?<!-- SHIFTLY_ALTERNATE_ICONS_END -->/,()=>`<!-- SHIFTLY_ALTERNATE_ICONS_START -->\n${aliases}\n        <!-- SHIFTLY_ALTERNATE_ICONS_END -->`);await write(manifestFile,manifest);
 const project='ios/Runner.xcodeproj/project.pbxproj';let pbx=await fs.readFile(path.join(root,project),'utf8');
 pbx=pbx.replace(/^\s*ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES = .*;\r?\n/gm,'').replace(/^\s*ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = .*;\r?\n/gm,'');
 const names=icons.map(i=>'Shiftly_'+i.key).join(' ');
 pbx=pbx.replace(/ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;/g,()=>`ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;\n\t\t\t\tASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES = "${names}";\n\t\t\t\tASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES;`);await write(project,pbx);
 await write('assets/app_icons/catalog.json',JSON.stringify({icons},null,2)+'\n');
 process.stdout.write(`Prepared ${icons.length} alternate app icons.\n`);
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
 try{
  const args=process.argv.slice(2);const value=k=>args.includes(k)?args[args.indexOf(k)+1]:undefined;
  let baseUrl=value('--base-url');const defines=value('--defines');
  if(defines)baseUrl=JSON.parse(await fs.readFile(defines,'utf8')).SHIFTLY_API_BASE_URL;
  const catalogFile=value('--catalog');if(!baseUrl&&!catalogFile)throw new Error('Pass --defines FILE, --base-url URL or --catalog FILE');
  await prepare({baseUrl,catalogFile});
 }catch(error){process.stderr.write(`App icon preparation failed: ${error.message}\n`);process.exitCode=1;}
}
