import {test} from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import {tmpdir} from 'node:os';
import path from 'node:path';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {encodeRgb,decodeIconPng} from './icon-png.ts';
test('packages a downloaded icon for Android/iOS and preserves shipped icons on later builds',async()=>{
 const temp=await fs.mkdtemp(path.join(tmpdir(),'shiftly-icons-'));
 const put=async(file,value)=>{await fs.mkdir(path.dirname(path.join(temp,file)),{recursive:true});await fs.writeFile(path.join(temp,file),value);};
 try{
  await put('scripts/prepare-app-icons.mjs',await fs.readFile(new URL('./prepare-app-icons.mjs',import.meta.url)));
  await put('scripts/icon-png.ts',await fs.readFile(new URL('./icon-png.ts',import.meta.url)));
  const image=encodeRgb(512,512,Buffer.alloc(512*512*3,90)),sha=createHash('sha256').update(image).digest('hex'),key='icon_'+sha;
  await put('assets/app_icons/catalog.json',JSON.stringify({icons:[]}));await put('assets/app_icons/'+sha+'.png',image);
  await put('catalog.json',JSON.stringify({icons:[{key,sha256:sha,name:'Ramadan',imagePath:'/platform/app-icons/images/'+sha+'.png'}]}));
  await put('android/app/src/main/AndroidManifest.xml','<application><!-- SHIFTLY_ALTERNATE_ICONS_START --><!-- SHIFTLY_ALTERNATE_ICONS_END --></application>');
  await put('ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json',JSON.stringify({images:[{idiom:'iphone',size:'60x60',scale:'3x',filename:'primary.png'},{idiom:'ios-marketing',size:'1024x1024',scale:'1x',filename:'marketing.png'}]}));
  await put('ios/Runner.xcodeproj/project.pbxproj','ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;');
  execFileSync(process.execPath,['scripts/prepare-app-icons.mjs','--catalog','catalog.json'],{cwd:temp});
  const manifest=await fs.readFile(path.join(temp,'android/app/src/main/AndroidManifest.xml'),'utf8');assert.match(manifest,new RegExp('Launcher_'+key));assert.match(manifest,/android:enabled="false"/);
  assert.equal(decodeIconPng(await fs.readFile(path.join(temp,`ios/Runner/Assets.xcassets/Shiftly_${key}.appiconset/icon-180-iphone.png`)),180).length,180*180*3);
  assert.match(await fs.readFile(path.join(temp,'ios/Runner.xcodeproj/project.pbxproj'),'utf8'),new RegExp('Shiftly_'+key));
  await put('catalog.json',JSON.stringify({icons:[]}));execFileSync(process.execPath,['scripts/prepare-app-icons.mjs','--catalog','catalog.json'],{cwd:temp});
  assert.equal(JSON.parse(await fs.readFile(path.join(temp,'assets/app_icons/catalog.json'),'utf8')).icons.length,1);
  await put('catalog.json',JSON.stringify({icons:[{key:'../escape',sha256:sha,imagePath:'/bad'}]}));
  assert.throws(()=>execFileSync(process.execPath,['scripts/prepare-app-icons.mjs','--catalog','catalog.json'],{cwd:temp,stdio:'pipe'}));
 }finally{const resolved=path.resolve(temp);if(!resolved.startsWith(path.join(tmpdir(),'shiftly-icons-')))throw Error('Unsafe fixture cleanup');await fs.rm(resolved,{recursive:true,force:true});}
});
