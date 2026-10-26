import { deflateSync, inflateSync } from 'node:zlib';
const signature=Buffer.from([137,80,78,71,13,10,26,10]);
export function crc32(bytes:Uint8Array):number {let c=0xffffffff;for(const b of bytes){c^=b;for(let i=0;i<8;i++)c=(c>>>1)^((c&1)?0xedb88320:0);}return (c^0xffffffff)>>>0;}
function chunk(type:string,data:Buffer){const name=Buffer.from(type);const size=Buffer.alloc(4);size.writeUInt32BE(data.length);const crc=Buffer.alloc(4);crc.writeUInt32BE(crc32(Buffer.concat([name,data])));return Buffer.concat([size,name,data,crc]);}
export function encodeRgb(width:number,height:number,rgb:Buffer):Buffer {
 if(rgb.length!==width*height*3)throw new Error('Invalid RGB length');
 const h=Buffer.alloc(13);h.writeUInt32BE(width);h.writeUInt32BE(height,4);h[8]=8;h[9]=2;
 const rows=Buffer.alloc(height*(1+width*3));for(let y=0;y<height;y++)rgb.copy(rows,y*(1+width*3)+1,y*width*3,(y+1)*width*3);
 return Buffer.concat([signature,chunk('IHDR',h),chunk('IDAT',deflateSync(rows)),chunk('IEND',Buffer.alloc(0))]);
}
const paeth=(a:number,b:number,c:number)=>{const p=a+b-c,pa=Math.abs(p-a),pb=Math.abs(p-b),pc=Math.abs(p-c);return pa<=pb&&pa<=pc?a:pb<=pc?b:c;};
// Accept only a bounded, static, opaque, square 8-bit RGB/RGBA PNG. Decode all
// rows and rewrite it to remove ancillary metadata and unexpected payloads.
export function decodeIconPng(bytes:Buffer,expectedSize=512):Buffer {
 if(bytes.length>1024*1024||!bytes.subarray(0,8).equals(signature))throw new Error('PNG_REQUIRED');
 let offset=8,channels=0,seenHeader=false,seenEnd=false,seenData=false,dataEnded=false;const data:Buffer[]=[];
 while(offset<bytes.length){
  if(offset+12>bytes.length)throw new Error('PNG_TRUNCATED');const length=bytes.readUInt32BE(offset);if(offset+12+length>bytes.length)throw new Error('PNG_TRUNCATED');
  const type=bytes.toString('ascii',offset+4,offset+8),payload=bytes.subarray(offset+8,offset+8+length);
  if(crc32(bytes.subarray(offset+4,offset+8+length))!==bytes.readUInt32BE(offset+8+length))throw new Error('PNG_CRC');
  if(!seenHeader&&type!=='IHDR')throw new Error('PNG_HEADER');
  if(type==='IHDR'){
   if(seenHeader||length!==13||payload.readUInt32BE(0)!==expectedSize||payload.readUInt32BE(4)!==expectedSize||payload[8]!==8||![2,6].includes(payload[9])||payload[10]||payload[11]||payload[12])throw new Error('PNG_DIMENSIONS_OR_FORMAT');
   channels=payload[9]===6?4:3;seenHeader=true;
  }else if(type==='IDAT'){if(dataEnded)throw new Error('PNG_DATA_ORDER');data.push(payload);seenData=true;}
  else if(type==='IEND'){if(length!==0||!seenData)throw new Error('PNG_END');seenEnd=true;offset+=12;break;}
  else {if(seenData)dataEnded=true;if(type==='acTL'||type==='tRNS'||(type.charCodeAt(0)&32)===0)throw new Error('PNG_STATIC_RGB_REQUIRED');}
  offset+=12+length;
 }
 if(!seenEnd||offset!==bytes.length)throw new Error('PNG_END');
 const stride=expectedSize*channels,raw=inflateSync(Buffer.concat(data),{maxOutputLength:(stride+1)*expectedSize});
 if(raw.length!==(stride+1)*expectedSize)throw new Error('PNG_ROWS');
 const decoded=Buffer.alloc(stride*expectedSize),rgb=Buffer.alloc(expectedSize*expectedSize*3);
 for(let y=0;y<expectedSize;y++){
  const filter=raw[y*(stride+1)];if(filter>4)throw new Error('PNG_FILTER');
  for(let x=0;x<stride;x++){
   const left=x>=channels?decoded[y*stride+x-channels]:0,up=y?decoded[(y-1)*stride+x]:0,corner=y&&x>=channels?decoded[(y-1)*stride+x-channels]:0;
   const predictor=[0,left,up,Math.floor((left+up)/2),paeth(left,up,corner)][filter];decoded[y*stride+x]=(raw[y*(stride+1)+1+x]+predictor)&255;
  }
 }
 for(let i=0;i<expectedSize*expectedSize;i++){
  if(channels===4&&decoded[i*4+3]!==255)throw new Error('PNG_MUST_BE_OPAQUE');
  decoded.copy(rgb,i*3,i*channels,i*channels+3);
 }
 return rgb;
}
export function resizeRgb(rgb:Buffer,size:number,sourceSize=512):Buffer {
 const output=Buffer.alloc(size*size*3);
 for(let y=0;y<size;y++)for(let x=0;x<size;x++){
  const sx=Math.max(0,Math.min(sourceSize-1,(x+0.5)*sourceSize/size-0.5)),sy=Math.max(0,Math.min(sourceSize-1,(y+0.5)*sourceSize/size-0.5));
  const x0=Math.floor(sx),y0=Math.floor(sy),x1=Math.min(x0+1,sourceSize-1),y1=Math.min(y0+1,sourceSize-1),dx=sx-x0,dy=sy-y0;
  for(let c=0;c<3;c++)output[(y*size+x)*3+c]=Math.round((1-dy)*((1-dx)*rgb[(y0*sourceSize+x0)*3+c]+dx*rgb[(y0*sourceSize+x1)*3+c])+dy*((1-dx)*rgb[(y1*sourceSize+x0)*3+c]+dx*rgb[(y1*sourceSize+x1)*3+c]));
 }
 return output;
}
