(()=>{function Uh(){let i=!1,e=n=>{let r=JSON.stringify({v:1,...n});window.LiveTips&&window.LiveTips.postMessage?window.LiveTips.postMessage(r):window.parent!==window?window.parent.postMessage({liveTipsStage:r},window.location.origin):console.log("[stage\u2192host]",r)},t={emit:e,onMessage:null,markReady(){i||(i=!0,e({type:"ready"}))},get isReady(){return i}};return window.__stage={dispatch(n){let r=null;try{r=typeof n=="string"?JSON.parse(n):n}catch(a){e({type:"error",message:"unparseable message: "+a,fatal:!1});return}if(!r||typeof r.type!="string"){e({type:"error",message:"message without type",fatal:!1});return}try{t.onMessage&&t.onMessage(r)}catch(a){e({type:"error",message:`handling '${r.type}': ${a&&a.stack||a}`,fatal:!1})}}},addEventListener("error",n=>{e({type:"error",message:String(n.message||n),fatal:!i})}),addEventListener("unhandledrejection",n=>{let r=n.reason;e({type:"error",message:"rejection: "+String(r&&r.message||r),fatal:!1})}),t}/**
 * @license
 * Copyright 2010-2025 Three.js Authors
 * SPDX-License-Identifier: MIT
 */var uu=0,sc=1,du=2;var oc=1,pu=2,si=3,oi=0,Xt=1,It=2,li=0,_r=1,Xn=2,lc=3,cc=4,fu=5,oa=100,mu=101,gu=102,vu=103,_u=104,yu=200,xu=201,Mu=202,Su=203,bu=204,Tu=205,Eu=206,wu=207,Au=208,Ru=209,Cu=210,Pu=211,Iu=212,Lu=213,Du=214,Fo=0,Oo=1,Bo=2,ss=3,ko=4,zo=5,Ho=6,Go=7,Uu=0,Nu=1,Fu=2,Pi=0,Ou=1,Bu=2,ku=3,Vo=4,zu=5,Hu=6,Gu=7;var hc=300,la=301,yr=302,Wo=303,Xo=304,os=306,Xi=1e3,$r=1001,Ys=1002,ii=1003,Vu=1004;var ls=1005;var ri=1006,jo=1007;var xr=1008;var ci=1009,uc=1010,dc=1011,ca=1012,qo=1013,Mr=1014,jn=1015,ha=1016,Yo=1017,Zo=1018,ua=1020,pc=35902,fc=35899,Wu=1021,Xu=1022,qn=1023,cs=1026,hs=1027,Jo=1028,Ko=1029,ju=1030,mc=1031;var gc=1033,$o=33776,Qo=33777,el=33778,tl=33779,vc=35840,_c=35841,yc=35842,xc=35843,Mc=36196,Sc=37492,bc=37496,Tc=37808,Ec=37809,wc=37810,Ac=37811,Rc=37812,Cc=37813,Pc=37814,Ic=37815,Lc=37816,Dc=37817,Uc=37818,Nc=37819,Fc=37820,Oc=37821,Bc=36492,kc=36494,zc=36495,Hc=36283,Gc=36284,Vc=36285,Wc=36286;var Na=2300,Zs=2301,qs=2302,Yl=2400,Zl=2401,Jl=2402;var qu=3201;var Yu=0,Zu=1,Sr="",Wt="srgb",pr="srgb-linear",Fa="linear",dt="srgb";var dr=7680;var Ju=512,Ku=513,$u=514,Xc=515,Qu=516,ed=517,td=518,nd=519,Kl=35044,jc=35048;var qc="300 es",Ei=2e3,Oa=2001;var wi=class{addEventListener(e,t){this._listeners===void 0&&(this._listeners={});let n=this._listeners;n[e]===void 0&&(n[e]=[]),n[e].indexOf(t)===-1&&n[e].push(t)}hasEventListener(e,t){let n=this._listeners;return n!==void 0&&n[e]!==void 0&&n[e].indexOf(t)!==-1}removeEventListener(e,t){let n=this._listeners;if(n===void 0)return;let r=n[e];if(r!==void 0){let a=r.indexOf(t);a!==-1&&r.splice(a,1)}}dispatchEvent(e){let t=this._listeners;if(t===void 0)return;let n=t[e.type];if(n!==void 0){e.target=this;let r=n.slice(0);for(let a=0,s=r.length;a<s;a++)r[a].call(this,e);e.target=null}}},tn=["00","01","02","03","04","05","06","07","08","09","0a","0b","0c","0d","0e","0f","10","11","12","13","14","15","16","17","18","19","1a","1b","1c","1d","1e","1f","20","21","22","23","24","25","26","27","28","29","2a","2b","2c","2d","2e","2f","30","31","32","33","34","35","36","37","38","39","3a","3b","3c","3d","3e","3f","40","41","42","43","44","45","46","47","48","49","4a","4b","4c","4d","4e","4f","50","51","52","53","54","55","56","57","58","59","5a","5b","5c","5d","5e","5f","60","61","62","63","64","65","66","67","68","69","6a","6b","6c","6d","6e","6f","70","71","72","73","74","75","76","77","78","79","7a","7b","7c","7d","7e","7f","80","81","82","83","84","85","86","87","88","89","8a","8b","8c","8d","8e","8f","90","91","92","93","94","95","96","97","98","99","9a","9b","9c","9d","9e","9f","a0","a1","a2","a3","a4","a5","a6","a7","a8","a9","aa","ab","ac","ad","ae","af","b0","b1","b2","b3","b4","b5","b6","b7","b8","b9","ba","bb","bc","bd","be","bf","c0","c1","c2","c3","c4","c5","c6","c7","c8","c9","ca","cb","cc","cd","ce","cf","d0","d1","d2","d3","d4","d5","d6","d7","d8","d9","da","db","dc","dd","de","df","e0","e1","e2","e3","e4","e5","e6","e7","e8","e9","ea","eb","ec","ed","ee","ef","f0","f1","f2","f3","f4","f5","f6","f7","f8","f9","fa","fb","fc","fd","fe","ff"],Nh=1234567,Jr=Math.PI/180,Qr=180/Math.PI;function br(){let i=4294967295*Math.random()|0,e=4294967295*Math.random()|0,t=4294967295*Math.random()|0,n=4294967295*Math.random()|0;return(tn[255&i]+tn[i>>8&255]+tn[i>>16&255]+tn[i>>24&255]+"-"+tn[255&e]+tn[e>>8&255]+"-"+tn[e>>16&15|64]+tn[e>>24&255]+"-"+tn[63&t|128]+tn[t>>8&255]+"-"+tn[t>>16&255]+tn[t>>24&255]+tn[255&n]+tn[n>>8&255]+tn[n>>16&255]+tn[n>>24&255]).toLowerCase()}function at(i,e,t){return Math.max(e,Math.min(t,i))}function $l(i,e){return(i%e+e)%e}function La(i,e,t){return(1-t)*i+t*e}function Zr(i,e){switch(e.constructor){case Float32Array:return i;case Uint32Array:return i/4294967295;case Uint16Array:return i/65535;case Uint8Array:return i/255;case Int32Array:return Math.max(i/2147483647,-1);case Int16Array:return Math.max(i/32767,-1);case Int8Array:return Math.max(i/127,-1);default:throw new Error("Invalid component type.")}}function dn(i,e){switch(e.constructor){case Float32Array:return i;case Uint32Array:return Math.round(4294967295*i);case Uint16Array:return Math.round(65535*i);case Uint8Array:return Math.round(255*i);case Int32Array:return Math.round(2147483647*i);case Int16Array:return Math.round(32767*i);case Int8Array:return Math.round(127*i);default:throw new Error("Invalid component type.")}}var mn={DEG2RAD:Jr,RAD2DEG:Qr,generateUUID:br,clamp:at,euclideanModulo:$l,mapLinear:function(i,e,t,n,r){return n+(i-e)*(r-n)/(t-e)},inverseLerp:function(i,e,t){return i!==e?(t-i)/(e-i):0},lerp:La,damp:function(i,e,t,n){return La(i,e,1-Math.exp(-t*n))},pingpong:function(i,e=1){return e-Math.abs($l(i,2*e)-e)},smoothstep:function(i,e,t){return i<=e?0:i>=t?1:(i=(i-e)/(t-e))*i*(3-2*i)},smootherstep:function(i,e,t){return i<=e?0:i>=t?1:(i=(i-e)/(t-e))*i*i*(i*(6*i-15)+10)},randInt:function(i,e){return i+Math.floor(Math.random()*(e-i+1))},randFloat:function(i,e){return i+Math.random()*(e-i)},randFloatSpread:function(i){return i*(.5-Math.random())},seededRandom:function(i){i!==void 0&&(Nh=i);let e=Nh+=1831565813;return e=Math.imul(e^e>>>15,1|e),e^=e+Math.imul(e^e>>>7,61|e),((e^e>>>14)>>>0)/4294967296},degToRad:function(i){return i*Jr},radToDeg:function(i){return i*Qr},isPowerOfTwo:function(i){return!(i&i-1)&&i!==0},ceilPowerOfTwo:function(i){return Math.pow(2,Math.ceil(Math.log(i)/Math.LN2))},floorPowerOfTwo:function(i){return Math.pow(2,Math.floor(Math.log(i)/Math.LN2))},setQuaternionFromProperEuler:function(i,e,t,n,r){let a=Math.cos,s=Math.sin,o=a(t/2),c=s(t/2),l=a((e+n)/2),h=s((e+n)/2),u=a((e-n)/2),d=s((e-n)/2),p=a((n-e)/2),m=s((n-e)/2);switch(r){case"XYX":i.set(o*h,c*u,c*d,o*l);break;case"YZY":i.set(c*d,o*h,c*u,o*l);break;case"ZXZ":i.set(c*u,c*d,o*h,o*l);break;case"XZX":i.set(o*h,c*m,c*p,o*l);break;case"YXY":i.set(c*p,o*h,c*m,o*l);break;case"ZYZ":i.set(c*m,c*p,o*h,o*l);break;default:console.warn("THREE.MathUtils: .setQuaternionFromProperEuler() encountered an unknown order: "+r)}},normalize:dn,denormalize:Zr},pe=class i{constructor(e=0,t=0){i.prototype.isVector2=!0,this.x=e,this.y=t}get width(){return this.x}set width(e){this.x=e}get height(){return this.y}set height(e){this.y=e}set(e,t){return this.x=e,this.y=t,this}setScalar(e){return this.x=e,this.y=e,this}setX(e){return this.x=e,this}setY(e){return this.y=e,this}setComponent(e,t){switch(e){case 0:this.x=t;break;case 1:this.y=t;break;default:throw new Error("index is out of range: "+e)}return this}getComponent(e){switch(e){case 0:return this.x;case 1:return this.y;default:throw new Error("index is out of range: "+e)}}clone(){return new this.constructor(this.x,this.y)}copy(e){return this.x=e.x,this.y=e.y,this}add(e){return this.x+=e.x,this.y+=e.y,this}addScalar(e){return this.x+=e,this.y+=e,this}addVectors(e,t){return this.x=e.x+t.x,this.y=e.y+t.y,this}addScaledVector(e,t){return this.x+=e.x*t,this.y+=e.y*t,this}sub(e){return this.x-=e.x,this.y-=e.y,this}subScalar(e){return this.x-=e,this.y-=e,this}subVectors(e,t){return this.x=e.x-t.x,this.y=e.y-t.y,this}multiply(e){return this.x*=e.x,this.y*=e.y,this}multiplyScalar(e){return this.x*=e,this.y*=e,this}divide(e){return this.x/=e.x,this.y/=e.y,this}divideScalar(e){return this.multiplyScalar(1/e)}applyMatrix3(e){let t=this.x,n=this.y,r=e.elements;return this.x=r[0]*t+r[3]*n+r[6],this.y=r[1]*t+r[4]*n+r[7],this}min(e){return this.x=Math.min(this.x,e.x),this.y=Math.min(this.y,e.y),this}max(e){return this.x=Math.max(this.x,e.x),this.y=Math.max(this.y,e.y),this}clamp(e,t){return this.x=at(this.x,e.x,t.x),this.y=at(this.y,e.y,t.y),this}clampScalar(e,t){return this.x=at(this.x,e,t),this.y=at(this.y,e,t),this}clampLength(e,t){let n=this.length();return this.divideScalar(n||1).multiplyScalar(at(n,e,t))}floor(){return this.x=Math.floor(this.x),this.y=Math.floor(this.y),this}ceil(){return this.x=Math.ceil(this.x),this.y=Math.ceil(this.y),this}round(){return this.x=Math.round(this.x),this.y=Math.round(this.y),this}roundToZero(){return this.x=Math.trunc(this.x),this.y=Math.trunc(this.y),this}negate(){return this.x=-this.x,this.y=-this.y,this}dot(e){return this.x*e.x+this.y*e.y}cross(e){return this.x*e.y-this.y*e.x}lengthSq(){return this.x*this.x+this.y*this.y}length(){return Math.sqrt(this.x*this.x+this.y*this.y)}manhattanLength(){return Math.abs(this.x)+Math.abs(this.y)}normalize(){return this.divideScalar(this.length()||1)}angle(){return Math.atan2(-this.y,-this.x)+Math.PI}angleTo(e){let t=Math.sqrt(this.lengthSq()*e.lengthSq());if(t===0)return Math.PI/2;let n=this.dot(e)/t;return Math.acos(at(n,-1,1))}distanceTo(e){return Math.sqrt(this.distanceToSquared(e))}distanceToSquared(e){let t=this.x-e.x,n=this.y-e.y;return t*t+n*n}manhattanDistanceTo(e){return Math.abs(this.x-e.x)+Math.abs(this.y-e.y)}setLength(e){return this.normalize().multiplyScalar(e)}lerp(e,t){return this.x+=(e.x-this.x)*t,this.y+=(e.y-this.y)*t,this}lerpVectors(e,t,n){return this.x=e.x+(t.x-e.x)*n,this.y=e.y+(t.y-e.y)*n,this}equals(e){return e.x===this.x&&e.y===this.y}fromArray(e,t=0){return this.x=e[t],this.y=e[t+1],this}toArray(e=[],t=0){return e[t]=this.x,e[t+1]=this.y,e}fromBufferAttribute(e,t){return this.x=e.getX(t),this.y=e.getY(t),this}rotateAround(e,t){let n=Math.cos(t),r=Math.sin(t),a=this.x-e.x,s=this.y-e.y;return this.x=a*n-s*r+e.x,this.y=a*r+s*n+e.y,this}random(){return this.x=Math.random(),this.y=Math.random(),this}*[Symbol.iterator](){yield this.x,yield this.y}},kt=class{constructor(e=0,t=0,n=0,r=1){this.isQuaternion=!0,this._x=e,this._y=t,this._z=n,this._w=r}static slerpFlat(e,t,n,r,a,s,o){let c=n[r+0],l=n[r+1],h=n[r+2],u=n[r+3],d=a[s+0],p=a[s+1],m=a[s+2],g=a[s+3];if(o===0)return e[t+0]=c,e[t+1]=l,e[t+2]=h,void(e[t+3]=u);if(o===1)return e[t+0]=d,e[t+1]=p,e[t+2]=m,void(e[t+3]=g);if(u!==g||c!==d||l!==p||h!==m){let f=1-o,v=c*d+l*p+h*m+u*g,_=v>=0?1:-1,y=1-v*v;if(y>Number.EPSILON){let w=Math.sqrt(y),R=Math.atan2(w,v*_);f=Math.sin(f*R)/w,o=Math.sin(o*R)/w}let S=o*_;if(c=c*f+d*S,l=l*f+p*S,h=h*f+m*S,u=u*f+g*S,f===1-o){let w=1/Math.sqrt(c*c+l*l+h*h+u*u);c*=w,l*=w,h*=w,u*=w}}e[t]=c,e[t+1]=l,e[t+2]=h,e[t+3]=u}static multiplyQuaternionsFlat(e,t,n,r,a,s){let o=n[r],c=n[r+1],l=n[r+2],h=n[r+3],u=a[s],d=a[s+1],p=a[s+2],m=a[s+3];return e[t]=o*m+h*u+c*p-l*d,e[t+1]=c*m+h*d+l*u-o*p,e[t+2]=l*m+h*p+o*d-c*u,e[t+3]=h*m-o*u-c*d-l*p,e}get x(){return this._x}set x(e){this._x=e,this._onChangeCallback()}get y(){return this._y}set y(e){this._y=e,this._onChangeCallback()}get z(){return this._z}set z(e){this._z=e,this._onChangeCallback()}get w(){return this._w}set w(e){this._w=e,this._onChangeCallback()}set(e,t,n,r){return this._x=e,this._y=t,this._z=n,this._w=r,this._onChangeCallback(),this}clone(){return new this.constructor(this._x,this._y,this._z,this._w)}copy(e){return this._x=e.x,this._y=e.y,this._z=e.z,this._w=e.w,this._onChangeCallback(),this}setFromEuler(e,t=!0){let n=e._x,r=e._y,a=e._z,s=e._order,o=Math.cos,c=Math.sin,l=o(n/2),h=o(r/2),u=o(a/2),d=c(n/2),p=c(r/2),m=c(a/2);switch(s){case"XYZ":this._x=d*h*u+l*p*m,this._y=l*p*u-d*h*m,this._z=l*h*m+d*p*u,this._w=l*h*u-d*p*m;break;case"YXZ":this._x=d*h*u+l*p*m,this._y=l*p*u-d*h*m,this._z=l*h*m-d*p*u,this._w=l*h*u+d*p*m;break;case"ZXY":this._x=d*h*u-l*p*m,this._y=l*p*u+d*h*m,this._z=l*h*m+d*p*u,this._w=l*h*u-d*p*m;break;case"ZYX":this._x=d*h*u-l*p*m,this._y=l*p*u+d*h*m,this._z=l*h*m-d*p*u,this._w=l*h*u+d*p*m;break;case"YZX":this._x=d*h*u+l*p*m,this._y=l*p*u+d*h*m,this._z=l*h*m-d*p*u,this._w=l*h*u-d*p*m;break;case"XZY":this._x=d*h*u-l*p*m,this._y=l*p*u-d*h*m,this._z=l*h*m+d*p*u,this._w=l*h*u+d*p*m;break;default:console.warn("THREE.Quaternion: .setFromEuler() encountered an unknown order: "+s)}return t===!0&&this._onChangeCallback(),this}setFromAxisAngle(e,t){let n=t/2,r=Math.sin(n);return this._x=e.x*r,this._y=e.y*r,this._z=e.z*r,this._w=Math.cos(n),this._onChangeCallback(),this}setFromRotationMatrix(e){let t=e.elements,n=t[0],r=t[4],a=t[8],s=t[1],o=t[5],c=t[9],l=t[2],h=t[6],u=t[10],d=n+o+u;if(d>0){let p=.5/Math.sqrt(d+1);this._w=.25/p,this._x=(h-c)*p,this._y=(a-l)*p,this._z=(s-r)*p}else if(n>o&&n>u){let p=2*Math.sqrt(1+n-o-u);this._w=(h-c)/p,this._x=.25*p,this._y=(r+s)/p,this._z=(a+l)/p}else if(o>u){let p=2*Math.sqrt(1+o-n-u);this._w=(a-l)/p,this._x=(r+s)/p,this._y=.25*p,this._z=(c+h)/p}else{let p=2*Math.sqrt(1+u-n-o);this._w=(s-r)/p,this._x=(a+l)/p,this._y=(c+h)/p,this._z=.25*p}return this._onChangeCallback(),this}setFromUnitVectors(e,t){let n=e.dot(t)+1;return n<1e-8?(n=0,Math.abs(e.x)>Math.abs(e.z)?(this._x=-e.y,this._y=e.x,this._z=0,this._w=n):(this._x=0,this._y=-e.z,this._z=e.y,this._w=n)):(this._x=e.y*t.z-e.z*t.y,this._y=e.z*t.x-e.x*t.z,this._z=e.x*t.y-e.y*t.x,this._w=n),this.normalize()}angleTo(e){return 2*Math.acos(Math.abs(at(this.dot(e),-1,1)))}rotateTowards(e,t){let n=this.angleTo(e);if(n===0)return this;let r=Math.min(1,t/n);return this.slerp(e,r),this}identity(){return this.set(0,0,0,1)}invert(){return this.conjugate()}conjugate(){return this._x*=-1,this._y*=-1,this._z*=-1,this._onChangeCallback(),this}dot(e){return this._x*e._x+this._y*e._y+this._z*e._z+this._w*e._w}lengthSq(){return this._x*this._x+this._y*this._y+this._z*this._z+this._w*this._w}length(){return Math.sqrt(this._x*this._x+this._y*this._y+this._z*this._z+this._w*this._w)}normalize(){let e=this.length();return e===0?(this._x=0,this._y=0,this._z=0,this._w=1):(e=1/e,this._x=this._x*e,this._y=this._y*e,this._z=this._z*e,this._w=this._w*e),this._onChangeCallback(),this}multiply(e){return this.multiplyQuaternions(this,e)}premultiply(e){return this.multiplyQuaternions(e,this)}multiplyQuaternions(e,t){let n=e._x,r=e._y,a=e._z,s=e._w,o=t._x,c=t._y,l=t._z,h=t._w;return this._x=n*h+s*o+r*l-a*c,this._y=r*h+s*c+a*o-n*l,this._z=a*h+s*l+n*c-r*o,this._w=s*h-n*o-r*c-a*l,this._onChangeCallback(),this}slerp(e,t){if(t===0)return this;if(t===1)return this.copy(e);let n=this._x,r=this._y,a=this._z,s=this._w,o=s*e._w+n*e._x+r*e._y+a*e._z;if(o<0?(this._w=-e._w,this._x=-e._x,this._y=-e._y,this._z=-e._z,o=-o):this.copy(e),o>=1)return this._w=s,this._x=n,this._y=r,this._z=a,this;let c=1-o*o;if(c<=Number.EPSILON){let p=1-t;return this._w=p*s+t*this._w,this._x=p*n+t*this._x,this._y=p*r+t*this._y,this._z=p*a+t*this._z,this.normalize(),this}let l=Math.sqrt(c),h=Math.atan2(l,o),u=Math.sin((1-t)*h)/l,d=Math.sin(t*h)/l;return this._w=s*u+this._w*d,this._x=n*u+this._x*d,this._y=r*u+this._y*d,this._z=a*u+this._z*d,this._onChangeCallback(),this}slerpQuaternions(e,t,n){return this.copy(e).slerp(t,n)}random(){let e=2*Math.PI*Math.random(),t=2*Math.PI*Math.random(),n=Math.random(),r=Math.sqrt(1-n),a=Math.sqrt(n);return this.set(r*Math.sin(e),r*Math.cos(e),a*Math.sin(t),a*Math.cos(t))}equals(e){return e._x===this._x&&e._y===this._y&&e._z===this._z&&e._w===this._w}fromArray(e,t=0){return this._x=e[t],this._y=e[t+1],this._z=e[t+2],this._w=e[t+3],this._onChangeCallback(),this}toArray(e=[],t=0){return e[t]=this._x,e[t+1]=this._y,e[t+2]=this._z,e[t+3]=this._w,e}fromBufferAttribute(e,t){return this._x=e.getX(t),this._y=e.getY(t),this._z=e.getZ(t),this._w=e.getW(t),this._onChangeCallback(),this}toJSON(){return this.toArray()}_onChange(e){return this._onChangeCallback=e,this}_onChangeCallback(){}*[Symbol.iterator](){yield this._x,yield this._y,yield this._z,yield this._w}},E=class i{constructor(e=0,t=0,n=0){i.prototype.isVector3=!0,this.x=e,this.y=t,this.z=n}set(e,t,n){return n===void 0&&(n=this.z),this.x=e,this.y=t,this.z=n,this}setScalar(e){return this.x=e,this.y=e,this.z=e,this}setX(e){return this.x=e,this}setY(e){return this.y=e,this}setZ(e){return this.z=e,this}setComponent(e,t){switch(e){case 0:this.x=t;break;case 1:this.y=t;break;case 2:this.z=t;break;default:throw new Error("index is out of range: "+e)}return this}getComponent(e){switch(e){case 0:return this.x;case 1:return this.y;case 2:return this.z;default:throw new Error("index is out of range: "+e)}}clone(){return new this.constructor(this.x,this.y,this.z)}copy(e){return this.x=e.x,this.y=e.y,this.z=e.z,this}add(e){return this.x+=e.x,this.y+=e.y,this.z+=e.z,this}addScalar(e){return this.x+=e,this.y+=e,this.z+=e,this}addVectors(e,t){return this.x=e.x+t.x,this.y=e.y+t.y,this.z=e.z+t.z,this}addScaledVector(e,t){return this.x+=e.x*t,this.y+=e.y*t,this.z+=e.z*t,this}sub(e){return this.x-=e.x,this.y-=e.y,this.z-=e.z,this}subScalar(e){return this.x-=e,this.y-=e,this.z-=e,this}subVectors(e,t){return this.x=e.x-t.x,this.y=e.y-t.y,this.z=e.z-t.z,this}multiply(e){return this.x*=e.x,this.y*=e.y,this.z*=e.z,this}multiplyScalar(e){return this.x*=e,this.y*=e,this.z*=e,this}multiplyVectors(e,t){return this.x=e.x*t.x,this.y=e.y*t.y,this.z=e.z*t.z,this}applyEuler(e){return this.applyQuaternion(Fh.setFromEuler(e))}applyAxisAngle(e,t){return this.applyQuaternion(Fh.setFromAxisAngle(e,t))}applyMatrix3(e){let t=this.x,n=this.y,r=this.z,a=e.elements;return this.x=a[0]*t+a[3]*n+a[6]*r,this.y=a[1]*t+a[4]*n+a[7]*r,this.z=a[2]*t+a[5]*n+a[8]*r,this}applyNormalMatrix(e){return this.applyMatrix3(e).normalize()}applyMatrix4(e){let t=this.x,n=this.y,r=this.z,a=e.elements,s=1/(a[3]*t+a[7]*n+a[11]*r+a[15]);return this.x=(a[0]*t+a[4]*n+a[8]*r+a[12])*s,this.y=(a[1]*t+a[5]*n+a[9]*r+a[13])*s,this.z=(a[2]*t+a[6]*n+a[10]*r+a[14])*s,this}applyQuaternion(e){let t=this.x,n=this.y,r=this.z,a=e.x,s=e.y,o=e.z,c=e.w,l=2*(s*r-o*n),h=2*(o*t-a*r),u=2*(a*n-s*t);return this.x=t+c*l+s*u-o*h,this.y=n+c*h+o*l-a*u,this.z=r+c*u+a*h-s*l,this}project(e){return this.applyMatrix4(e.matrixWorldInverse).applyMatrix4(e.projectionMatrix)}unproject(e){return this.applyMatrix4(e.projectionMatrixInverse).applyMatrix4(e.matrixWorld)}transformDirection(e){let t=this.x,n=this.y,r=this.z,a=e.elements;return this.x=a[0]*t+a[4]*n+a[8]*r,this.y=a[1]*t+a[5]*n+a[9]*r,this.z=a[2]*t+a[6]*n+a[10]*r,this.normalize()}divide(e){return this.x/=e.x,this.y/=e.y,this.z/=e.z,this}divideScalar(e){return this.multiplyScalar(1/e)}min(e){return this.x=Math.min(this.x,e.x),this.y=Math.min(this.y,e.y),this.z=Math.min(this.z,e.z),this}max(e){return this.x=Math.max(this.x,e.x),this.y=Math.max(this.y,e.y),this.z=Math.max(this.z,e.z),this}clamp(e,t){return this.x=at(this.x,e.x,t.x),this.y=at(this.y,e.y,t.y),this.z=at(this.z,e.z,t.z),this}clampScalar(e,t){return this.x=at(this.x,e,t),this.y=at(this.y,e,t),this.z=at(this.z,e,t),this}clampLength(e,t){let n=this.length();return this.divideScalar(n||1).multiplyScalar(at(n,e,t))}floor(){return this.x=Math.floor(this.x),this.y=Math.floor(this.y),this.z=Math.floor(this.z),this}ceil(){return this.x=Math.ceil(this.x),this.y=Math.ceil(this.y),this.z=Math.ceil(this.z),this}round(){return this.x=Math.round(this.x),this.y=Math.round(this.y),this.z=Math.round(this.z),this}roundToZero(){return this.x=Math.trunc(this.x),this.y=Math.trunc(this.y),this.z=Math.trunc(this.z),this}negate(){return this.x=-this.x,this.y=-this.y,this.z=-this.z,this}dot(e){return this.x*e.x+this.y*e.y+this.z*e.z}lengthSq(){return this.x*this.x+this.y*this.y+this.z*this.z}length(){return Math.sqrt(this.x*this.x+this.y*this.y+this.z*this.z)}manhattanLength(){return Math.abs(this.x)+Math.abs(this.y)+Math.abs(this.z)}normalize(){return this.divideScalar(this.length()||1)}setLength(e){return this.normalize().multiplyScalar(e)}lerp(e,t){return this.x+=(e.x-this.x)*t,this.y+=(e.y-this.y)*t,this.z+=(e.z-this.z)*t,this}lerpVectors(e,t,n){return this.x=e.x+(t.x-e.x)*n,this.y=e.y+(t.y-e.y)*n,this.z=e.z+(t.z-e.z)*n,this}cross(e){return this.crossVectors(this,e)}crossVectors(e,t){let n=e.x,r=e.y,a=e.z,s=t.x,o=t.y,c=t.z;return this.x=r*c-a*o,this.y=a*s-n*c,this.z=n*o-r*s,this}projectOnVector(e){let t=e.lengthSq();if(t===0)return this.set(0,0,0);let n=e.dot(this)/t;return this.copy(e).multiplyScalar(n)}projectOnPlane(e){return Ml.copy(this).projectOnVector(e),this.sub(Ml)}reflect(e){return this.sub(Ml.copy(e).multiplyScalar(2*this.dot(e)))}angleTo(e){let t=Math.sqrt(this.lengthSq()*e.lengthSq());if(t===0)return Math.PI/2;let n=this.dot(e)/t;return Math.acos(at(n,-1,1))}distanceTo(e){return Math.sqrt(this.distanceToSquared(e))}distanceToSquared(e){let t=this.x-e.x,n=this.y-e.y,r=this.z-e.z;return t*t+n*n+r*r}manhattanDistanceTo(e){return Math.abs(this.x-e.x)+Math.abs(this.y-e.y)+Math.abs(this.z-e.z)}setFromSpherical(e){return this.setFromSphericalCoords(e.radius,e.phi,e.theta)}setFromSphericalCoords(e,t,n){let r=Math.sin(t)*e;return this.x=r*Math.sin(n),this.y=Math.cos(t)*e,this.z=r*Math.cos(n),this}setFromCylindrical(e){return this.setFromCylindricalCoords(e.radius,e.theta,e.y)}setFromCylindricalCoords(e,t,n){return this.x=e*Math.sin(t),this.y=n,this.z=e*Math.cos(t),this}setFromMatrixPosition(e){let t=e.elements;return this.x=t[12],this.y=t[13],this.z=t[14],this}setFromMatrixScale(e){let t=this.setFromMatrixColumn(e,0).length(),n=this.setFromMatrixColumn(e,1).length(),r=this.setFromMatrixColumn(e,2).length();return this.x=t,this.y=n,this.z=r,this}setFromMatrixColumn(e,t){return this.fromArray(e.elements,4*t)}setFromMatrix3Column(e,t){return this.fromArray(e.elements,3*t)}setFromEuler(e){return this.x=e._x,this.y=e._y,this.z=e._z,this}setFromColor(e){return this.x=e.r,this.y=e.g,this.z=e.b,this}equals(e){return e.x===this.x&&e.y===this.y&&e.z===this.z}fromArray(e,t=0){return this.x=e[t],this.y=e[t+1],this.z=e[t+2],this}toArray(e=[],t=0){return e[t]=this.x,e[t+1]=this.y,e[t+2]=this.z,e}fromBufferAttribute(e,t){return this.x=e.getX(t),this.y=e.getY(t),this.z=e.getZ(t),this}random(){return this.x=Math.random(),this.y=Math.random(),this.z=Math.random(),this}randomDirection(){let e=Math.random()*Math.PI*2,t=2*Math.random()-1,n=Math.sqrt(1-t*t);return this.x=n*Math.cos(e),this.y=t,this.z=n*Math.sin(e),this}*[Symbol.iterator](){yield this.x,yield this.y,yield this.z}},Ml=new E,Fh=new kt,Qe=class i{constructor(e,t,n,r,a,s,o,c,l){i.prototype.isMatrix3=!0,this.elements=[1,0,0,0,1,0,0,0,1],e!==void 0&&this.set(e,t,n,r,a,s,o,c,l)}set(e,t,n,r,a,s,o,c,l){let h=this.elements;return h[0]=e,h[1]=r,h[2]=o,h[3]=t,h[4]=a,h[5]=c,h[6]=n,h[7]=s,h[8]=l,this}identity(){return this.set(1,0,0,0,1,0,0,0,1),this}copy(e){let t=this.elements,n=e.elements;return t[0]=n[0],t[1]=n[1],t[2]=n[2],t[3]=n[3],t[4]=n[4],t[5]=n[5],t[6]=n[6],t[7]=n[7],t[8]=n[8],this}extractBasis(e,t,n){return e.setFromMatrix3Column(this,0),t.setFromMatrix3Column(this,1),n.setFromMatrix3Column(this,2),this}setFromMatrix4(e){let t=e.elements;return this.set(t[0],t[4],t[8],t[1],t[5],t[9],t[2],t[6],t[10]),this}multiply(e){return this.multiplyMatrices(this,e)}premultiply(e){return this.multiplyMatrices(e,this)}multiplyMatrices(e,t){let n=e.elements,r=t.elements,a=this.elements,s=n[0],o=n[3],c=n[6],l=n[1],h=n[4],u=n[7],d=n[2],p=n[5],m=n[8],g=r[0],f=r[3],v=r[6],_=r[1],y=r[4],S=r[7],w=r[2],R=r[5],B=r[8];return a[0]=s*g+o*_+c*w,a[3]=s*f+o*y+c*R,a[6]=s*v+o*S+c*B,a[1]=l*g+h*_+u*w,a[4]=l*f+h*y+u*R,a[7]=l*v+h*S+u*B,a[2]=d*g+p*_+m*w,a[5]=d*f+p*y+m*R,a[8]=d*v+p*S+m*B,this}multiplyScalar(e){let t=this.elements;return t[0]*=e,t[3]*=e,t[6]*=e,t[1]*=e,t[4]*=e,t[7]*=e,t[2]*=e,t[5]*=e,t[8]*=e,this}determinant(){let e=this.elements,t=e[0],n=e[1],r=e[2],a=e[3],s=e[4],o=e[5],c=e[6],l=e[7],h=e[8];return t*s*h-t*o*l-n*a*h+n*o*c+r*a*l-r*s*c}invert(){let e=this.elements,t=e[0],n=e[1],r=e[2],a=e[3],s=e[4],o=e[5],c=e[6],l=e[7],h=e[8],u=h*s-o*l,d=o*c-h*a,p=l*a-s*c,m=t*u+n*d+r*p;if(m===0)return this.set(0,0,0,0,0,0,0,0,0);let g=1/m;return e[0]=u*g,e[1]=(r*l-h*n)*g,e[2]=(o*n-r*s)*g,e[3]=d*g,e[4]=(h*t-r*c)*g,e[5]=(r*a-o*t)*g,e[6]=p*g,e[7]=(n*c-l*t)*g,e[8]=(s*t-n*a)*g,this}transpose(){let e,t=this.elements;return e=t[1],t[1]=t[3],t[3]=e,e=t[2],t[2]=t[6],t[6]=e,e=t[5],t[5]=t[7],t[7]=e,this}getNormalMatrix(e){return this.setFromMatrix4(e).invert().transpose()}transposeIntoArray(e){let t=this.elements;return e[0]=t[0],e[1]=t[3],e[2]=t[6],e[3]=t[1],e[4]=t[4],e[5]=t[7],e[6]=t[2],e[7]=t[5],e[8]=t[8],this}setUvTransform(e,t,n,r,a,s,o){let c=Math.cos(a),l=Math.sin(a);return this.set(n*c,n*l,-n*(c*s+l*o)+s+e,-r*l,r*c,-r*(-l*s+c*o)+o+t,0,0,1),this}scale(e,t){return this.premultiply(Sl.makeScale(e,t)),this}rotate(e){return this.premultiply(Sl.makeRotation(-e)),this}translate(e,t){return this.premultiply(Sl.makeTranslation(e,t)),this}makeTranslation(e,t){return e.isVector2?this.set(1,0,e.x,0,1,e.y,0,0,1):this.set(1,0,e,0,1,t,0,0,1),this}makeRotation(e){let t=Math.cos(e),n=Math.sin(e);return this.set(t,-n,0,n,t,0,0,0,1),this}makeScale(e,t){return this.set(e,0,0,0,t,0,0,0,1),this}equals(e){let t=this.elements,n=e.elements;for(let r=0;r<9;r++)if(t[r]!==n[r])return!1;return!0}fromArray(e,t=0){for(let n=0;n<9;n++)this.elements[n]=e[n+t];return this}toArray(e=[],t=0){let n=this.elements;return e[t]=n[0],e[t+1]=n[1],e[t+2]=n[2],e[t+3]=n[3],e[t+4]=n[4],e[t+5]=n[5],e[t+6]=n[6],e[t+7]=n[7],e[t+8]=n[8],e}clone(){return new this.constructor().fromArray(this.elements)}},Sl=new Qe;function Yc(i){for(let e=i.length-1;e>=0;--e)if(i[e]>=65535)return!0;return!1}function Ba(i){return document.createElementNS("http://www.w3.org/1999/xhtml",i)}function id(){let i=Ba("canvas");return i.style.display="block",i}var Oh={};function ea(i){i in Oh||(Oh[i]=!0,console.warn(i))}function rd(i,e,t){return new Promise(function(n,r){setTimeout(function a(){switch(i.clientWaitSync(e,i.SYNC_FLUSH_COMMANDS_BIT,0)){case i.WAIT_FAILED:r();break;case i.TIMEOUT_EXPIRED:setTimeout(a,t);break;default:n()}},t)})}var Bh=new Qe().set(.4123908,.3575843,.1804808,.212639,.7151687,.0721923,.0193308,.1191948,.9505322),kh=new Qe().set(3.2409699,-1.5373832,-.4986108,-.9692436,1.8759675,.0415551,.0556301,-.203977,1.0569715);function hp(){let i={enabled:!0,workingColorSpace:pr,spaces:{},convert:function(r,a,s){return this.enabled!==!1&&a!==s&&a&&s&&(this.spaces[a].transfer===dt&&(r.r=Ti(r.r),r.g=Ti(r.g),r.b=Ti(r.b)),this.spaces[a].primaries!==this.spaces[s].primaries&&(r.applyMatrix3(this.spaces[a].toXYZ),r.applyMatrix3(this.spaces[s].fromXYZ)),this.spaces[s].transfer===dt&&(r.r=Kr(r.r),r.g=Kr(r.g),r.b=Kr(r.b))),r},workingToColorSpace:function(r,a){return this.convert(r,this.workingColorSpace,a)},colorSpaceToWorking:function(r,a){return this.convert(r,a,this.workingColorSpace)},getPrimaries:function(r){return this.spaces[r].primaries},getTransfer:function(r){return r===""?Fa:this.spaces[r].transfer},getToneMappingMode:function(r){return this.spaces[r].outputColorSpaceConfig.toneMappingMode||"standard"},getLuminanceCoefficients:function(r,a=this.workingColorSpace){return r.fromArray(this.spaces[a].luminanceCoefficients)},define:function(r){Object.assign(this.spaces,r)},_getMatrix:function(r,a,s){return r.copy(this.spaces[a].toXYZ).multiply(this.spaces[s].fromXYZ)},_getDrawingBufferColorSpace:function(r){return this.spaces[r].outputColorSpaceConfig.drawingBufferColorSpace},_getUnpackColorSpace:function(r=this.workingColorSpace){return this.spaces[r].workingColorSpaceConfig.unpackColorSpace},fromWorkingColorSpace:function(r,a){return ea("THREE.ColorManagement: .fromWorkingColorSpace() has been renamed to .workingToColorSpace()."),i.workingToColorSpace(r,a)},toWorkingColorSpace:function(r,a){return ea("THREE.ColorManagement: .toWorkingColorSpace() has been renamed to .colorSpaceToWorking()."),i.colorSpaceToWorking(r,a)}},e=[.64,.33,.3,.6,.15,.06],t=[.2126,.7152,.0722],n=[.3127,.329];return i.define({[pr]:{primaries:e,whitePoint:n,transfer:Fa,toXYZ:Bh,fromXYZ:kh,luminanceCoefficients:t,workingColorSpaceConfig:{unpackColorSpace:Wt},outputColorSpaceConfig:{drawingBufferColorSpace:Wt}},[Wt]:{primaries:e,whitePoint:n,transfer:dt,toXYZ:Bh,fromXYZ:kh,luminanceCoefficients:t,outputColorSpaceConfig:{drawingBufferColorSpace:Wt}}}),i}var ht=hp();function Ti(i){return i<.04045?.0773993808*i:Math.pow(.9478672986*i+.0521327014,2.4)}function Kr(i){return i<.0031308?12.92*i:1.055*Math.pow(i,.41666)-.055}var Or,Js=class{static getDataURL(e,t="image/png"){if(/^data:/i.test(e.src)||typeof HTMLCanvasElement=="undefined")return e.src;let n;if(e instanceof HTMLCanvasElement)n=e;else{Or===void 0&&(Or=Ba("canvas")),Or.width=e.width,Or.height=e.height;let r=Or.getContext("2d");e instanceof ImageData?r.putImageData(e,0,0):r.drawImage(e,0,0,e.width,e.height),n=Or}return n.toDataURL(t)}static sRGBToLinear(e){if(typeof HTMLImageElement!="undefined"&&e instanceof HTMLImageElement||typeof HTMLCanvasElement!="undefined"&&e instanceof HTMLCanvasElement||typeof ImageBitmap!="undefined"&&e instanceof ImageBitmap){let t=Ba("canvas");t.width=e.width,t.height=e.height;let n=t.getContext("2d");n.drawImage(e,0,0,e.width,e.height);let r=n.getImageData(0,0,e.width,e.height),a=r.data;for(let s=0;s<a.length;s++)a[s]=255*Ti(a[s]/255);return n.putImageData(r,0,0),t}if(e.data){let t=e.data.slice(0);for(let n=0;n<t.length;n++)t instanceof Uint8Array||t instanceof Uint8ClampedArray?t[n]=Math.floor(255*Ti(t[n]/255)):t[n]=Ti(t[n]);return{data:t,width:e.width,height:e.height}}return console.warn("THREE.ImageUtils.sRGBToLinear(): Unsupported image type. No color space conversion applied."),e}},up=0,ta=class{constructor(e=null){this.isSource=!0,Object.defineProperty(this,"id",{value:up++}),this.uuid=br(),this.data=e,this.dataReady=!0,this.version=0}getSize(e){let t=this.data;return typeof HTMLVideoElement!="undefined"&&t instanceof HTMLVideoElement?e.set(t.videoWidth,t.videoHeight,0):t instanceof VideoFrame?e.set(t.displayHeight,t.displayWidth,0):t!==null?e.set(t.width,t.height,t.depth||0):e.set(0,0,0),e}set needsUpdate(e){e===!0&&this.version++}toJSON(e){let t=e===void 0||typeof e=="string";if(!t&&e.images[this.uuid]!==void 0)return e.images[this.uuid];let n={uuid:this.uuid,url:""},r=this.data;if(r!==null){let a;if(Array.isArray(r)){a=[];for(let s=0,o=r.length;s<o;s++)r[s].isDataTexture?a.push(bl(r[s].image)):a.push(bl(r[s]))}else a=bl(r);n.url=a}return t||(e.images[this.uuid]=n),n}};function bl(i){return typeof HTMLImageElement!="undefined"&&i instanceof HTMLImageElement||typeof HTMLCanvasElement!="undefined"&&i instanceof HTMLCanvasElement||typeof ImageBitmap!="undefined"&&i instanceof ImageBitmap?Js.getDataURL(i):i.data?{data:Array.from(i.data),width:i.width,height:i.height,type:i.data.constructor.name}:(console.warn("THREE.Texture: Unable to serialize Texture."),{})}var dp=0,Tl=new E,fn=class i extends wi{constructor(e=i.DEFAULT_IMAGE,t=i.DEFAULT_MAPPING,n=1001,r=1001,a=1006,s=1008,o=1023,c=1009,l=i.DEFAULT_ANISOTROPY,h=""){super(),this.isTexture=!0,Object.defineProperty(this,"id",{value:dp++}),this.uuid=br(),this.name="",this.source=new ta(e),this.mipmaps=[],this.mapping=t,this.channel=0,this.wrapS=n,this.wrapT=r,this.magFilter=a,this.minFilter=s,this.anisotropy=l,this.format=o,this.internalFormat=null,this.type=c,this.offset=new pe(0,0),this.repeat=new pe(1,1),this.center=new pe(0,0),this.rotation=0,this.matrixAutoUpdate=!0,this.matrix=new Qe,this.generateMipmaps=!0,this.premultiplyAlpha=!1,this.flipY=!0,this.unpackAlignment=4,this.colorSpace=h,this.userData={},this.updateRanges=[],this.version=0,this.onUpdate=null,this.renderTarget=null,this.isRenderTargetTexture=!1,this.isArrayTexture=!!(e&&e.depth&&e.depth>1),this.pmremVersion=0}get width(){return this.source.getSize(Tl).x}get height(){return this.source.getSize(Tl).y}get depth(){return this.source.getSize(Tl).z}get image(){return this.source.data}set image(e=null){this.source.data=e}updateMatrix(){this.matrix.setUvTransform(this.offset.x,this.offset.y,this.repeat.x,this.repeat.y,this.rotation,this.center.x,this.center.y)}addUpdateRange(e,t){this.updateRanges.push({start:e,count:t})}clearUpdateRanges(){this.updateRanges.length=0}clone(){return new this.constructor().copy(this)}copy(e){return this.name=e.name,this.source=e.source,this.mipmaps=e.mipmaps.slice(0),this.mapping=e.mapping,this.channel=e.channel,this.wrapS=e.wrapS,this.wrapT=e.wrapT,this.magFilter=e.magFilter,this.minFilter=e.minFilter,this.anisotropy=e.anisotropy,this.format=e.format,this.internalFormat=e.internalFormat,this.type=e.type,this.offset.copy(e.offset),this.repeat.copy(e.repeat),this.center.copy(e.center),this.rotation=e.rotation,this.matrixAutoUpdate=e.matrixAutoUpdate,this.matrix.copy(e.matrix),this.generateMipmaps=e.generateMipmaps,this.premultiplyAlpha=e.premultiplyAlpha,this.flipY=e.flipY,this.unpackAlignment=e.unpackAlignment,this.colorSpace=e.colorSpace,this.renderTarget=e.renderTarget,this.isRenderTargetTexture=e.isRenderTargetTexture,this.isArrayTexture=e.isArrayTexture,this.userData=JSON.parse(JSON.stringify(e.userData)),this.needsUpdate=!0,this}setValues(e){for(let t in e){let n=e[t];if(n===void 0){console.warn(`THREE.Texture.setValues(): parameter '${t}' has value of undefined.`);continue}let r=this[t];r!==void 0?r&&n&&r.isVector2&&n.isVector2||r&&n&&r.isVector3&&n.isVector3||r&&n&&r.isMatrix3&&n.isMatrix3?r.copy(n):this[t]=n:console.warn(`THREE.Texture.setValues(): property '${t}' does not exist.`)}}toJSON(e){let t=e===void 0||typeof e=="string";if(!t&&e.textures[this.uuid]!==void 0)return e.textures[this.uuid];let n={metadata:{version:4.7,type:"Texture",generator:"Texture.toJSON"},uuid:this.uuid,name:this.name,image:this.source.toJSON(e).uuid,mapping:this.mapping,channel:this.channel,repeat:[this.repeat.x,this.repeat.y],offset:[this.offset.x,this.offset.y],center:[this.center.x,this.center.y],rotation:this.rotation,wrap:[this.wrapS,this.wrapT],format:this.format,internalFormat:this.internalFormat,type:this.type,colorSpace:this.colorSpace,minFilter:this.minFilter,magFilter:this.magFilter,anisotropy:this.anisotropy,flipY:this.flipY,generateMipmaps:this.generateMipmaps,premultiplyAlpha:this.premultiplyAlpha,unpackAlignment:this.unpackAlignment};return Object.keys(this.userData).length>0&&(n.userData=this.userData),t||(e.textures[this.uuid]=n),n}dispose(){this.dispatchEvent({type:"dispose"})}transformUv(e){if(this.mapping!==hc)return e;if(e.applyMatrix3(this.matrix),e.x<0||e.x>1)switch(this.wrapS){case Xi:e.x=e.x-Math.floor(e.x);break;case $r:e.x=e.x<0?0:1;break;case Ys:Math.abs(Math.floor(e.x)%2)===1?e.x=Math.ceil(e.x)-e.x:e.x=e.x-Math.floor(e.x)}if(e.y<0||e.y>1)switch(this.wrapT){case Xi:e.y=e.y-Math.floor(e.y);break;case $r:e.y=e.y<0?0:1;break;case Ys:Math.abs(Math.floor(e.y)%2)===1?e.y=Math.ceil(e.y)-e.y:e.y=e.y-Math.floor(e.y)}return this.flipY&&(e.y=1-e.y),e}set needsUpdate(e){e===!0&&(this.version++,this.source.needsUpdate=!0)}set needsPMREMUpdate(e){e===!0&&this.pmremVersion++}};fn.DEFAULT_IMAGE=null,fn.DEFAULT_MAPPING=hc,fn.DEFAULT_ANISOTROPY=1;var xt=class i{constructor(e=0,t=0,n=0,r=1){i.prototype.isVector4=!0,this.x=e,this.y=t,this.z=n,this.w=r}get width(){return this.z}set width(e){this.z=e}get height(){return this.w}set height(e){this.w=e}set(e,t,n,r){return this.x=e,this.y=t,this.z=n,this.w=r,this}setScalar(e){return this.x=e,this.y=e,this.z=e,this.w=e,this}setX(e){return this.x=e,this}setY(e){return this.y=e,this}setZ(e){return this.z=e,this}setW(e){return this.w=e,this}setComponent(e,t){switch(e){case 0:this.x=t;break;case 1:this.y=t;break;case 2:this.z=t;break;case 3:this.w=t;break;default:throw new Error("index is out of range: "+e)}return this}getComponent(e){switch(e){case 0:return this.x;case 1:return this.y;case 2:return this.z;case 3:return this.w;default:throw new Error("index is out of range: "+e)}}clone(){return new this.constructor(this.x,this.y,this.z,this.w)}copy(e){return this.x=e.x,this.y=e.y,this.z=e.z,this.w=e.w!==void 0?e.w:1,this}add(e){return this.x+=e.x,this.y+=e.y,this.z+=e.z,this.w+=e.w,this}addScalar(e){return this.x+=e,this.y+=e,this.z+=e,this.w+=e,this}addVectors(e,t){return this.x=e.x+t.x,this.y=e.y+t.y,this.z=e.z+t.z,this.w=e.w+t.w,this}addScaledVector(e,t){return this.x+=e.x*t,this.y+=e.y*t,this.z+=e.z*t,this.w+=e.w*t,this}sub(e){return this.x-=e.x,this.y-=e.y,this.z-=e.z,this.w-=e.w,this}subScalar(e){return this.x-=e,this.y-=e,this.z-=e,this.w-=e,this}subVectors(e,t){return this.x=e.x-t.x,this.y=e.y-t.y,this.z=e.z-t.z,this.w=e.w-t.w,this}multiply(e){return this.x*=e.x,this.y*=e.y,this.z*=e.z,this.w*=e.w,this}multiplyScalar(e){return this.x*=e,this.y*=e,this.z*=e,this.w*=e,this}applyMatrix4(e){let t=this.x,n=this.y,r=this.z,a=this.w,s=e.elements;return this.x=s[0]*t+s[4]*n+s[8]*r+s[12]*a,this.y=s[1]*t+s[5]*n+s[9]*r+s[13]*a,this.z=s[2]*t+s[6]*n+s[10]*r+s[14]*a,this.w=s[3]*t+s[7]*n+s[11]*r+s[15]*a,this}divide(e){return this.x/=e.x,this.y/=e.y,this.z/=e.z,this.w/=e.w,this}divideScalar(e){return this.multiplyScalar(1/e)}setAxisAngleFromQuaternion(e){this.w=2*Math.acos(e.w);let t=Math.sqrt(1-e.w*e.w);return t<1e-4?(this.x=1,this.y=0,this.z=0):(this.x=e.x/t,this.y=e.y/t,this.z=e.z/t),this}setAxisAngleFromRotationMatrix(e){let t,n,r,a,c=e.elements,l=c[0],h=c[4],u=c[8],d=c[1],p=c[5],m=c[9],g=c[2],f=c[6],v=c[10];if(Math.abs(h-d)<.01&&Math.abs(u-g)<.01&&Math.abs(m-f)<.01){if(Math.abs(h+d)<.1&&Math.abs(u+g)<.1&&Math.abs(m+f)<.1&&Math.abs(l+p+v-3)<.1)return this.set(1,0,0,0),this;t=Math.PI;let y=(l+1)/2,S=(p+1)/2,w=(v+1)/2,R=(h+d)/4,B=(u+g)/4,G=(m+f)/4;return y>S&&y>w?y<.01?(n=0,r=.707106781,a=.707106781):(n=Math.sqrt(y),r=R/n,a=B/n):S>w?S<.01?(n=.707106781,r=0,a=.707106781):(r=Math.sqrt(S),n=R/r,a=G/r):w<.01?(n=.707106781,r=.707106781,a=0):(a=Math.sqrt(w),n=B/a,r=G/a),this.set(n,r,a,t),this}let _=Math.sqrt((f-m)*(f-m)+(u-g)*(u-g)+(d-h)*(d-h));return Math.abs(_)<.001&&(_=1),this.x=(f-m)/_,this.y=(u-g)/_,this.z=(d-h)/_,this.w=Math.acos((l+p+v-1)/2),this}setFromMatrixPosition(e){let t=e.elements;return this.x=t[12],this.y=t[13],this.z=t[14],this.w=t[15],this}min(e){return this.x=Math.min(this.x,e.x),this.y=Math.min(this.y,e.y),this.z=Math.min(this.z,e.z),this.w=Math.min(this.w,e.w),this}max(e){return this.x=Math.max(this.x,e.x),this.y=Math.max(this.y,e.y),this.z=Math.max(this.z,e.z),this.w=Math.max(this.w,e.w),this}clamp(e,t){return this.x=at(this.x,e.x,t.x),this.y=at(this.y,e.y,t.y),this.z=at(this.z,e.z,t.z),this.w=at(this.w,e.w,t.w),this}clampScalar(e,t){return this.x=at(this.x,e,t),this.y=at(this.y,e,t),this.z=at(this.z,e,t),this.w=at(this.w,e,t),this}clampLength(e,t){let n=this.length();return this.divideScalar(n||1).multiplyScalar(at(n,e,t))}floor(){return this.x=Math.floor(this.x),this.y=Math.floor(this.y),this.z=Math.floor(this.z),this.w=Math.floor(this.w),this}ceil(){return this.x=Math.ceil(this.x),this.y=Math.ceil(this.y),this.z=Math.ceil(this.z),this.w=Math.ceil(this.w),this}round(){return this.x=Math.round(this.x),this.y=Math.round(this.y),this.z=Math.round(this.z),this.w=Math.round(this.w),this}roundToZero(){return this.x=Math.trunc(this.x),this.y=Math.trunc(this.y),this.z=Math.trunc(this.z),this.w=Math.trunc(this.w),this}negate(){return this.x=-this.x,this.y=-this.y,this.z=-this.z,this.w=-this.w,this}dot(e){return this.x*e.x+this.y*e.y+this.z*e.z+this.w*e.w}lengthSq(){return this.x*this.x+this.y*this.y+this.z*this.z+this.w*this.w}length(){return Math.sqrt(this.x*this.x+this.y*this.y+this.z*this.z+this.w*this.w)}manhattanLength(){return Math.abs(this.x)+Math.abs(this.y)+Math.abs(this.z)+Math.abs(this.w)}normalize(){return this.divideScalar(this.length()||1)}setLength(e){return this.normalize().multiplyScalar(e)}lerp(e,t){return this.x+=(e.x-this.x)*t,this.y+=(e.y-this.y)*t,this.z+=(e.z-this.z)*t,this.w+=(e.w-this.w)*t,this}lerpVectors(e,t,n){return this.x=e.x+(t.x-e.x)*n,this.y=e.y+(t.y-e.y)*n,this.z=e.z+(t.z-e.z)*n,this.w=e.w+(t.w-e.w)*n,this}equals(e){return e.x===this.x&&e.y===this.y&&e.z===this.z&&e.w===this.w}fromArray(e,t=0){return this.x=e[t],this.y=e[t+1],this.z=e[t+2],this.w=e[t+3],this}toArray(e=[],t=0){return e[t]=this.x,e[t+1]=this.y,e[t+2]=this.z,e[t+3]=this.w,e}fromBufferAttribute(e,t){return this.x=e.getX(t),this.y=e.getY(t),this.z=e.getZ(t),this.w=e.getW(t),this}random(){return this.x=Math.random(),this.y=Math.random(),this.z=Math.random(),this.w=Math.random(),this}*[Symbol.iterator](){yield this.x,yield this.y,yield this.z,yield this.w}},Ks=class extends wi{constructor(e=1,t=1,n={}){super(),n=Object.assign({generateMipmaps:!1,internalFormat:null,minFilter:ri,depthBuffer:!0,stencilBuffer:!1,resolveDepthBuffer:!0,resolveStencilBuffer:!0,depthTexture:null,samples:0,count:1,depth:1,multiview:!1},n),this.isRenderTarget=!0,this.width=e,this.height=t,this.depth=n.depth,this.scissor=new xt(0,0,e,t),this.scissorTest=!1,this.viewport=new xt(0,0,e,t);let r={width:e,height:t,depth:n.depth},a=new fn(r);this.textures=[];let s=n.count;for(let o=0;o<s;o++)this.textures[o]=a.clone(),this.textures[o].isRenderTargetTexture=!0,this.textures[o].renderTarget=this;this._setTextureOptions(n),this.depthBuffer=n.depthBuffer,this.stencilBuffer=n.stencilBuffer,this.resolveDepthBuffer=n.resolveDepthBuffer,this.resolveStencilBuffer=n.resolveStencilBuffer,this._depthTexture=null,this.depthTexture=n.depthTexture,this.samples=n.samples,this.multiview=n.multiview}_setTextureOptions(e={}){let t={minFilter:ri,generateMipmaps:!1,flipY:!1,internalFormat:null};e.mapping!==void 0&&(t.mapping=e.mapping),e.wrapS!==void 0&&(t.wrapS=e.wrapS),e.wrapT!==void 0&&(t.wrapT=e.wrapT),e.wrapR!==void 0&&(t.wrapR=e.wrapR),e.magFilter!==void 0&&(t.magFilter=e.magFilter),e.minFilter!==void 0&&(t.minFilter=e.minFilter),e.format!==void 0&&(t.format=e.format),e.type!==void 0&&(t.type=e.type),e.anisotropy!==void 0&&(t.anisotropy=e.anisotropy),e.colorSpace!==void 0&&(t.colorSpace=e.colorSpace),e.flipY!==void 0&&(t.flipY=e.flipY),e.generateMipmaps!==void 0&&(t.generateMipmaps=e.generateMipmaps),e.internalFormat!==void 0&&(t.internalFormat=e.internalFormat);for(let n=0;n<this.textures.length;n++)this.textures[n].setValues(t)}get texture(){return this.textures[0]}set texture(e){this.textures[0]=e}set depthTexture(e){this._depthTexture!==null&&(this._depthTexture.renderTarget=null),e!==null&&(e.renderTarget=this),this._depthTexture=e}get depthTexture(){return this._depthTexture}setSize(e,t,n=1){if(this.width!==e||this.height!==t||this.depth!==n){this.width=e,this.height=t,this.depth=n;for(let r=0,a=this.textures.length;r<a;r++)this.textures[r].image.width=e,this.textures[r].image.height=t,this.textures[r].image.depth=n,this.textures[r].isArrayTexture=this.textures[r].image.depth>1;this.dispose()}this.viewport.set(0,0,e,t),this.scissor.set(0,0,e,t)}clone(){return new this.constructor().copy(this)}copy(e){this.width=e.width,this.height=e.height,this.depth=e.depth,this.scissor.copy(e.scissor),this.scissorTest=e.scissorTest,this.viewport.copy(e.viewport),this.textures.length=0;for(let t=0,n=e.textures.length;t<n;t++){this.textures[t]=e.textures[t].clone(),this.textures[t].isRenderTargetTexture=!0,this.textures[t].renderTarget=this;let r=Object.assign({},e.textures[t].image);this.textures[t].source=new ta(r)}return this.depthBuffer=e.depthBuffer,this.stencilBuffer=e.stencilBuffer,this.resolveDepthBuffer=e.resolveDepthBuffer,this.resolveStencilBuffer=e.resolveStencilBuffer,e.depthTexture!==null&&(this.depthTexture=e.depthTexture.clone()),this.samples=e.samples,this}dispose(){this.dispatchEvent({type:"dispose"})}},yn=class extends Ks{constructor(e=1,t=1,n={}){super(e,t,n),this.isWebGLRenderTarget=!0}},ka=class extends fn{constructor(e=null,t=1,n=1,r=1){super(null),this.isDataArrayTexture=!0,this.image={data:e,width:t,height:n,depth:r},this.magFilter=ii,this.minFilter=ii,this.wrapR=$r,this.generateMipmaps=!1,this.flipY=!1,this.unpackAlignment=1,this.layerUpdates=new Set}addLayerUpdate(e){this.layerUpdates.add(e)}clearLayerUpdates(){this.layerUpdates.clear()}};var $s=class extends fn{constructor(e=null,t=1,n=1,r=1){super(null),this.isData3DTexture=!0,this.image={data:e,width:t,height:n,depth:r},this.magFilter=ii,this.minFilter=ii,this.wrapR=$r,this.generateMipmaps=!1,this.flipY=!1,this.unpackAlignment=1}};var Nn=class{constructor(e=new E(1/0,1/0,1/0),t=new E(-1/0,-1/0,-1/0)){this.isBox3=!0,this.min=e,this.max=t}set(e,t){return this.min.copy(e),this.max.copy(t),this}setFromArray(e){this.makeEmpty();for(let t=0,n=e.length;t<n;t+=3)this.expandByPoint(Hn.fromArray(e,t));return this}setFromBufferAttribute(e){this.makeEmpty();for(let t=0,n=e.count;t<n;t++)this.expandByPoint(Hn.fromBufferAttribute(e,t));return this}setFromPoints(e){this.makeEmpty();for(let t=0,n=e.length;t<n;t++)this.expandByPoint(e[t]);return this}setFromCenterAndSize(e,t){let n=Hn.copy(t).multiplyScalar(.5);return this.min.copy(e).sub(n),this.max.copy(e).add(n),this}setFromObject(e,t=!1){return this.makeEmpty(),this.expandByObject(e,t)}clone(){return new this.constructor().copy(this)}copy(e){return this.min.copy(e.min),this.max.copy(e.max),this}makeEmpty(){return this.min.x=this.min.y=this.min.z=1/0,this.max.x=this.max.y=this.max.z=-1/0,this}isEmpty(){return this.max.x<this.min.x||this.max.y<this.min.y||this.max.z<this.min.z}getCenter(e){return this.isEmpty()?e.set(0,0,0):e.addVectors(this.min,this.max).multiplyScalar(.5)}getSize(e){return this.isEmpty()?e.set(0,0,0):e.subVectors(this.max,this.min)}expandByPoint(e){return this.min.min(e),this.max.max(e),this}expandByVector(e){return this.min.sub(e),this.max.add(e),this}expandByScalar(e){return this.min.addScalar(-e),this.max.addScalar(e),this}expandByObject(e,t=!1){e.updateWorldMatrix(!1,!1);let n=e.geometry;if(n!==void 0){let a=n.getAttribute("position");if(t===!0&&a!==void 0&&e.isInstancedMesh!==!0)for(let s=0,o=a.count;s<o;s++)e.isMesh===!0?e.getVertexPosition(s,Hn):Hn.fromBufferAttribute(a,s),Hn.applyMatrix4(e.matrixWorld),this.expandByPoint(Hn);else e.boundingBox!==void 0?(e.boundingBox===null&&e.computeBoundingBox(),xs.copy(e.boundingBox)):(n.boundingBox===null&&n.computeBoundingBox(),xs.copy(n.boundingBox)),xs.applyMatrix4(e.matrixWorld),this.union(xs)}let r=e.children;for(let a=0,s=r.length;a<s;a++)this.expandByObject(r[a],t);return this}containsPoint(e){return e.x>=this.min.x&&e.x<=this.max.x&&e.y>=this.min.y&&e.y<=this.max.y&&e.z>=this.min.z&&e.z<=this.max.z}containsBox(e){return this.min.x<=e.min.x&&e.max.x<=this.max.x&&this.min.y<=e.min.y&&e.max.y<=this.max.y&&this.min.z<=e.min.z&&e.max.z<=this.max.z}getParameter(e,t){return t.set((e.x-this.min.x)/(this.max.x-this.min.x),(e.y-this.min.y)/(this.max.y-this.min.y),(e.z-this.min.z)/(this.max.z-this.min.z))}intersectsBox(e){return e.max.x>=this.min.x&&e.min.x<=this.max.x&&e.max.y>=this.min.y&&e.min.y<=this.max.y&&e.max.z>=this.min.z&&e.min.z<=this.max.z}intersectsSphere(e){return this.clampPoint(e.center,Hn),Hn.distanceToSquared(e.center)<=e.radius*e.radius}intersectsPlane(e){let t,n;return e.normal.x>0?(t=e.normal.x*this.min.x,n=e.normal.x*this.max.x):(t=e.normal.x*this.max.x,n=e.normal.x*this.min.x),e.normal.y>0?(t+=e.normal.y*this.min.y,n+=e.normal.y*this.max.y):(t+=e.normal.y*this.max.y,n+=e.normal.y*this.min.y),e.normal.z>0?(t+=e.normal.z*this.min.z,n+=e.normal.z*this.max.z):(t+=e.normal.z*this.max.z,n+=e.normal.z*this.min.z),t<=-e.constant&&n>=-e.constant}intersectsTriangle(e){if(this.isEmpty())return!1;this.getCenter(Ea),Ms.subVectors(this.max,Ea),Br.subVectors(e.a,Ea),kr.subVectors(e.b,Ea),zr.subVectors(e.c,Ea),Oi.subVectors(kr,Br),Bi.subVectors(zr,kr),lr.subVectors(Br,zr);let t=[0,-Oi.z,Oi.y,0,-Bi.z,Bi.y,0,-lr.z,lr.y,Oi.z,0,-Oi.x,Bi.z,0,-Bi.x,lr.z,0,-lr.x,-Oi.y,Oi.x,0,-Bi.y,Bi.x,0,-lr.y,lr.x,0];return!!El(t,Br,kr,zr,Ms)&&(t=[1,0,0,0,1,0,0,0,1],!!El(t,Br,kr,zr,Ms)&&(Ss.crossVectors(Oi,Bi),t=[Ss.x,Ss.y,Ss.z],El(t,Br,kr,zr,Ms)))}clampPoint(e,t){return t.copy(e).clamp(this.min,this.max)}distanceToPoint(e){return this.clampPoint(e,Hn).distanceTo(e)}getBoundingSphere(e){return this.isEmpty()?e.makeEmpty():(this.getCenter(e.center),e.radius=.5*this.getSize(Hn).length()),e}intersect(e){return this.min.max(e.min),this.max.min(e.max),this.isEmpty()&&this.makeEmpty(),this}union(e){return this.min.min(e.min),this.max.max(e.max),this}applyMatrix4(e){return this.isEmpty()||(_i[0].set(this.min.x,this.min.y,this.min.z).applyMatrix4(e),_i[1].set(this.min.x,this.min.y,this.max.z).applyMatrix4(e),_i[2].set(this.min.x,this.max.y,this.min.z).applyMatrix4(e),_i[3].set(this.min.x,this.max.y,this.max.z).applyMatrix4(e),_i[4].set(this.max.x,this.min.y,this.min.z).applyMatrix4(e),_i[5].set(this.max.x,this.min.y,this.max.z).applyMatrix4(e),_i[6].set(this.max.x,this.max.y,this.min.z).applyMatrix4(e),_i[7].set(this.max.x,this.max.y,this.max.z).applyMatrix4(e),this.setFromPoints(_i)),this}translate(e){return this.min.add(e),this.max.add(e),this}equals(e){return e.min.equals(this.min)&&e.max.equals(this.max)}toJSON(){return{min:this.min.toArray(),max:this.max.toArray()}}fromJSON(e){return this.min.fromArray(e.min),this.max.fromArray(e.max),this}},_i=[new E,new E,new E,new E,new E,new E,new E,new E],Hn=new E,xs=new Nn,Br=new E,kr=new E,zr=new E,Oi=new E,Bi=new E,lr=new E,Ea=new E,Ms=new E,Ss=new E,cr=new E;function El(i,e,t,n,r){for(let a=0,s=i.length-3;a<=s;a+=3){cr.fromArray(i,a);let o=r.x*Math.abs(cr.x)+r.y*Math.abs(cr.y)+r.z*Math.abs(cr.z),c=e.dot(cr),l=t.dot(cr),h=n.dot(cr);if(Math.max(-Math.max(c,l,h),Math.min(c,l,h))>o)return!1}return!0}var pp=new Nn,wa=new E,wl=new E,Fn=class{constructor(e=new E,t=-1){this.isSphere=!0,this.center=e,this.radius=t}set(e,t){return this.center.copy(e),this.radius=t,this}setFromPoints(e,t){let n=this.center;t!==void 0?n.copy(t):pp.setFromPoints(e).getCenter(n);let r=0;for(let a=0,s=e.length;a<s;a++)r=Math.max(r,n.distanceToSquared(e[a]));return this.radius=Math.sqrt(r),this}copy(e){return this.center.copy(e.center),this.radius=e.radius,this}isEmpty(){return this.radius<0}makeEmpty(){return this.center.set(0,0,0),this.radius=-1,this}containsPoint(e){return e.distanceToSquared(this.center)<=this.radius*this.radius}distanceToPoint(e){return e.distanceTo(this.center)-this.radius}intersectsSphere(e){let t=this.radius+e.radius;return e.center.distanceToSquared(this.center)<=t*t}intersectsBox(e){return e.intersectsSphere(this)}intersectsPlane(e){return Math.abs(e.distanceToPoint(this.center))<=this.radius}clampPoint(e,t){let n=this.center.distanceToSquared(e);return t.copy(e),n>this.radius*this.radius&&(t.sub(this.center).normalize(),t.multiplyScalar(this.radius).add(this.center)),t}getBoundingBox(e){return this.isEmpty()?(e.makeEmpty(),e):(e.set(this.center,this.center),e.expandByScalar(this.radius),e)}applyMatrix4(e){return this.center.applyMatrix4(e),this.radius=this.radius*e.getMaxScaleOnAxis(),this}translate(e){return this.center.add(e),this}expandByPoint(e){if(this.isEmpty())return this.center.copy(e),this.radius=0,this;wa.subVectors(e,this.center);let t=wa.lengthSq();if(t>this.radius*this.radius){let n=Math.sqrt(t),r=.5*(n-this.radius);this.center.addScaledVector(wa,r/n),this.radius+=r}return this}union(e){return e.isEmpty()?this:this.isEmpty()?(this.copy(e),this):(this.center.equals(e.center)===!0?this.radius=Math.max(this.radius,e.radius):(wl.subVectors(e.center,this.center).setLength(e.radius),this.expandByPoint(wa.copy(e.center).add(wl)),this.expandByPoint(wa.copy(e.center).sub(wl))),this)}equals(e){return e.center.equals(this.center)&&e.radius===this.radius}clone(){return new this.constructor().copy(this)}toJSON(){return{radius:this.radius,center:this.center.toArray()}}fromJSON(e){return this.radius=e.radius,this.center.fromArray(e.center),this}},yi=new E,Al=new E,bs=new E,ki=new E,Rl=new E,Ts=new E,Cl=new E,fr=class{constructor(e=new E,t=new E(0,0,-1)){this.origin=e,this.direction=t}set(e,t){return this.origin.copy(e),this.direction.copy(t),this}copy(e){return this.origin.copy(e.origin),this.direction.copy(e.direction),this}at(e,t){return t.copy(this.origin).addScaledVector(this.direction,e)}lookAt(e){return this.direction.copy(e).sub(this.origin).normalize(),this}recast(e){return this.origin.copy(this.at(e,yi)),this}closestPointToPoint(e,t){t.subVectors(e,this.origin);let n=t.dot(this.direction);return n<0?t.copy(this.origin):t.copy(this.origin).addScaledVector(this.direction,n)}distanceToPoint(e){return Math.sqrt(this.distanceSqToPoint(e))}distanceSqToPoint(e){let t=yi.subVectors(e,this.origin).dot(this.direction);return t<0?this.origin.distanceToSquared(e):(yi.copy(this.origin).addScaledVector(this.direction,t),yi.distanceToSquared(e))}distanceSqToSegment(e,t,n,r){Al.copy(e).add(t).multiplyScalar(.5),bs.copy(t).sub(e).normalize(),ki.copy(this.origin).sub(Al);let a=.5*e.distanceTo(t),s=-this.direction.dot(bs),o=ki.dot(this.direction),c=-ki.dot(bs),l=ki.lengthSq(),h=Math.abs(1-s*s),u,d,p,m;if(h>0)if(u=s*c-o,d=s*o-c,m=a*h,u>=0)if(d>=-m)if(d<=m){let g=1/h;u*=g,d*=g,p=u*(u+s*d+2*o)+d*(s*u+d+2*c)+l}else d=a,u=Math.max(0,-(s*d+o)),p=-u*u+d*(d+2*c)+l;else d=-a,u=Math.max(0,-(s*d+o)),p=-u*u+d*(d+2*c)+l;else d<=-m?(u=Math.max(0,-(-s*a+o)),d=u>0?-a:Math.min(Math.max(-a,-c),a),p=-u*u+d*(d+2*c)+l):d<=m?(u=0,d=Math.min(Math.max(-a,-c),a),p=d*(d+2*c)+l):(u=Math.max(0,-(s*a+o)),d=u>0?a:Math.min(Math.max(-a,-c),a),p=-u*u+d*(d+2*c)+l);else d=s>0?-a:a,u=Math.max(0,-(s*d+o)),p=-u*u+d*(d+2*c)+l;return n&&n.copy(this.origin).addScaledVector(this.direction,u),r&&r.copy(Al).addScaledVector(bs,d),p}intersectSphere(e,t){yi.subVectors(e.center,this.origin);let n=yi.dot(this.direction),r=yi.dot(yi)-n*n,a=e.radius*e.radius;if(r>a)return null;let s=Math.sqrt(a-r),o=n-s,c=n+s;return c<0?null:o<0?this.at(c,t):this.at(o,t)}intersectsSphere(e){return!(e.radius<0)&&this.distanceSqToPoint(e.center)<=e.radius*e.radius}distanceToPlane(e){let t=e.normal.dot(this.direction);if(t===0)return e.distanceToPoint(this.origin)===0?0:null;let n=-(this.origin.dot(e.normal)+e.constant)/t;return n>=0?n:null}intersectPlane(e,t){let n=this.distanceToPlane(e);return n===null?null:this.at(n,t)}intersectsPlane(e){let t=e.distanceToPoint(this.origin);return t===0?!0:e.normal.dot(this.direction)*t<0}intersectBox(e,t){let n,r,a,s,o,c,l=1/this.direction.x,h=1/this.direction.y,u=1/this.direction.z,d=this.origin;return l>=0?(n=(e.min.x-d.x)*l,r=(e.max.x-d.x)*l):(n=(e.max.x-d.x)*l,r=(e.min.x-d.x)*l),h>=0?(a=(e.min.y-d.y)*h,s=(e.max.y-d.y)*h):(a=(e.max.y-d.y)*h,s=(e.min.y-d.y)*h),n>s||a>r?null:((a>n||isNaN(n))&&(n=a),(s<r||isNaN(r))&&(r=s),u>=0?(o=(e.min.z-d.z)*u,c=(e.max.z-d.z)*u):(o=(e.max.z-d.z)*u,c=(e.min.z-d.z)*u),n>c||o>r?null:((o>n||n!=n)&&(n=o),(c<r||r!=r)&&(r=c),r<0?null:this.at(n>=0?n:r,t)))}intersectsBox(e){return this.intersectBox(e,yi)!==null}intersectTriangle(e,t,n,r,a){Rl.subVectors(t,e),Ts.subVectors(n,e),Cl.crossVectors(Rl,Ts);let s,o=this.direction.dot(Cl);if(o>0){if(r)return null;s=1}else{if(!(o<0))return null;s=-1,o=-o}ki.subVectors(this.origin,e);let c=s*this.direction.dot(Ts.crossVectors(ki,Ts));if(c<0)return null;let l=s*this.direction.dot(Rl.cross(ki));if(l<0||c+l>o)return null;let h=-s*ki.dot(Cl);return h<0?null:this.at(h/o,a)}applyMatrix4(e){return this.origin.applyMatrix4(e),this.direction.transformDirection(e),this}equals(e){return e.origin.equals(this.origin)&&e.direction.equals(this.direction)}clone(){return new this.constructor().copy(this)}},qe=class i{constructor(e,t,n,r,a,s,o,c,l,h,u,d,p,m,g,f){i.prototype.isMatrix4=!0,this.elements=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1],e!==void 0&&this.set(e,t,n,r,a,s,o,c,l,h,u,d,p,m,g,f)}set(e,t,n,r,a,s,o,c,l,h,u,d,p,m,g,f){let v=this.elements;return v[0]=e,v[4]=t,v[8]=n,v[12]=r,v[1]=a,v[5]=s,v[9]=o,v[13]=c,v[2]=l,v[6]=h,v[10]=u,v[14]=d,v[3]=p,v[7]=m,v[11]=g,v[15]=f,this}identity(){return this.set(1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1),this}clone(){return new i().fromArray(this.elements)}copy(e){let t=this.elements,n=e.elements;return t[0]=n[0],t[1]=n[1],t[2]=n[2],t[3]=n[3],t[4]=n[4],t[5]=n[5],t[6]=n[6],t[7]=n[7],t[8]=n[8],t[9]=n[9],t[10]=n[10],t[11]=n[11],t[12]=n[12],t[13]=n[13],t[14]=n[14],t[15]=n[15],this}copyPosition(e){let t=this.elements,n=e.elements;return t[12]=n[12],t[13]=n[13],t[14]=n[14],this}setFromMatrix3(e){let t=e.elements;return this.set(t[0],t[3],t[6],0,t[1],t[4],t[7],0,t[2],t[5],t[8],0,0,0,0,1),this}extractBasis(e,t,n){return e.setFromMatrixColumn(this,0),t.setFromMatrixColumn(this,1),n.setFromMatrixColumn(this,2),this}makeBasis(e,t,n){return this.set(e.x,t.x,n.x,0,e.y,t.y,n.y,0,e.z,t.z,n.z,0,0,0,0,1),this}extractRotation(e){let t=this.elements,n=e.elements,r=1/Hr.setFromMatrixColumn(e,0).length(),a=1/Hr.setFromMatrixColumn(e,1).length(),s=1/Hr.setFromMatrixColumn(e,2).length();return t[0]=n[0]*r,t[1]=n[1]*r,t[2]=n[2]*r,t[3]=0,t[4]=n[4]*a,t[5]=n[5]*a,t[6]=n[6]*a,t[7]=0,t[8]=n[8]*s,t[9]=n[9]*s,t[10]=n[10]*s,t[11]=0,t[12]=0,t[13]=0,t[14]=0,t[15]=1,this}makeRotationFromEuler(e){let t=this.elements,n=e.x,r=e.y,a=e.z,s=Math.cos(n),o=Math.sin(n),c=Math.cos(r),l=Math.sin(r),h=Math.cos(a),u=Math.sin(a);if(e.order==="XYZ"){let d=s*h,p=s*u,m=o*h,g=o*u;t[0]=c*h,t[4]=-c*u,t[8]=l,t[1]=p+m*l,t[5]=d-g*l,t[9]=-o*c,t[2]=g-d*l,t[6]=m+p*l,t[10]=s*c}else if(e.order==="YXZ"){let d=c*h,p=c*u,m=l*h,g=l*u;t[0]=d+g*o,t[4]=m*o-p,t[8]=s*l,t[1]=s*u,t[5]=s*h,t[9]=-o,t[2]=p*o-m,t[6]=g+d*o,t[10]=s*c}else if(e.order==="ZXY"){let d=c*h,p=c*u,m=l*h,g=l*u;t[0]=d-g*o,t[4]=-s*u,t[8]=m+p*o,t[1]=p+m*o,t[5]=s*h,t[9]=g-d*o,t[2]=-s*l,t[6]=o,t[10]=s*c}else if(e.order==="ZYX"){let d=s*h,p=s*u,m=o*h,g=o*u;t[0]=c*h,t[4]=m*l-p,t[8]=d*l+g,t[1]=c*u,t[5]=g*l+d,t[9]=p*l-m,t[2]=-l,t[6]=o*c,t[10]=s*c}else if(e.order==="YZX"){let d=s*c,p=s*l,m=o*c,g=o*l;t[0]=c*h,t[4]=g-d*u,t[8]=m*u+p,t[1]=u,t[5]=s*h,t[9]=-o*h,t[2]=-l*h,t[6]=p*u+m,t[10]=d-g*u}else if(e.order==="XZY"){let d=s*c,p=s*l,m=o*c,g=o*l;t[0]=c*h,t[4]=-u,t[8]=l*h,t[1]=d*u+g,t[5]=s*h,t[9]=p*u-m,t[2]=m*u-p,t[6]=o*h,t[10]=g*u+d}return t[3]=0,t[7]=0,t[11]=0,t[12]=0,t[13]=0,t[14]=0,t[15]=1,this}makeRotationFromQuaternion(e){return this.compose(fp,e,mp)}lookAt(e,t,n){let r=this.elements;return bn.subVectors(e,t),bn.lengthSq()===0&&(bn.z=1),bn.normalize(),zi.crossVectors(n,bn),zi.lengthSq()===0&&(Math.abs(n.z)===1?bn.x+=1e-4:bn.z+=1e-4,bn.normalize(),zi.crossVectors(n,bn)),zi.normalize(),Es.crossVectors(bn,zi),r[0]=zi.x,r[4]=Es.x,r[8]=bn.x,r[1]=zi.y,r[5]=Es.y,r[9]=bn.y,r[2]=zi.z,r[6]=Es.z,r[10]=bn.z,this}multiply(e){return this.multiplyMatrices(this,e)}premultiply(e){return this.multiplyMatrices(e,this)}multiplyMatrices(e,t){let n=e.elements,r=t.elements,a=this.elements,s=n[0],o=n[4],c=n[8],l=n[12],h=n[1],u=n[5],d=n[9],p=n[13],m=n[2],g=n[6],f=n[10],v=n[14],_=n[3],y=n[7],S=n[11],w=n[15],R=r[0],B=r[4],G=r[8],D=r[12],J=r[1],K=r[5],V=r[9],se=r[13],X=r[2],ee=r[6],Q=r[10],me=r[14],ae=r[3],be=r[7],Be=r[11],Ie=r[15];return a[0]=s*R+o*J+c*X+l*ae,a[4]=s*B+o*K+c*ee+l*be,a[8]=s*G+o*V+c*Q+l*Be,a[12]=s*D+o*se+c*me+l*Ie,a[1]=h*R+u*J+d*X+p*ae,a[5]=h*B+u*K+d*ee+p*be,a[9]=h*G+u*V+d*Q+p*Be,a[13]=h*D+u*se+d*me+p*Ie,a[2]=m*R+g*J+f*X+v*ae,a[6]=m*B+g*K+f*ee+v*be,a[10]=m*G+g*V+f*Q+v*Be,a[14]=m*D+g*se+f*me+v*Ie,a[3]=_*R+y*J+S*X+w*ae,a[7]=_*B+y*K+S*ee+w*be,a[11]=_*G+y*V+S*Q+w*Be,a[15]=_*D+y*se+S*me+w*Ie,this}multiplyScalar(e){let t=this.elements;return t[0]*=e,t[4]*=e,t[8]*=e,t[12]*=e,t[1]*=e,t[5]*=e,t[9]*=e,t[13]*=e,t[2]*=e,t[6]*=e,t[10]*=e,t[14]*=e,t[3]*=e,t[7]*=e,t[11]*=e,t[15]*=e,this}determinant(){let e=this.elements,t=e[0],n=e[4],r=e[8],a=e[12],s=e[1],o=e[5],c=e[9],l=e[13],h=e[2],u=e[6],d=e[10],p=e[14];return e[3]*(+a*c*u-r*l*u-a*o*d+n*l*d+r*o*p-n*c*p)+e[7]*(+t*c*p-t*l*d+a*s*d-r*s*p+r*l*h-a*c*h)+e[11]*(+t*l*u-t*o*p-a*s*u+n*s*p+a*o*h-n*l*h)+e[15]*(-r*o*h-t*c*u+t*o*d+r*s*u-n*s*d+n*c*h)}transpose(){let e=this.elements,t;return t=e[1],e[1]=e[4],e[4]=t,t=e[2],e[2]=e[8],e[8]=t,t=e[6],e[6]=e[9],e[9]=t,t=e[3],e[3]=e[12],e[12]=t,t=e[7],e[7]=e[13],e[13]=t,t=e[11],e[11]=e[14],e[14]=t,this}setPosition(e,t,n){let r=this.elements;return e.isVector3?(r[12]=e.x,r[13]=e.y,r[14]=e.z):(r[12]=e,r[13]=t,r[14]=n),this}invert(){let e=this.elements,t=e[0],n=e[1],r=e[2],a=e[3],s=e[4],o=e[5],c=e[6],l=e[7],h=e[8],u=e[9],d=e[10],p=e[11],m=e[12],g=e[13],f=e[14],v=e[15],_=u*f*l-g*d*l+g*c*p-o*f*p-u*c*v+o*d*v,y=m*d*l-h*f*l-m*c*p+s*f*p+h*c*v-s*d*v,S=h*g*l-m*u*l+m*o*p-s*g*p-h*o*v+s*u*v,w=m*u*c-h*g*c-m*o*d+s*g*d+h*o*f-s*u*f,R=t*_+n*y+r*S+a*w;if(R===0)return this.set(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);let B=1/R;return e[0]=_*B,e[1]=(g*d*a-u*f*a-g*r*p+n*f*p+u*r*v-n*d*v)*B,e[2]=(o*f*a-g*c*a+g*r*l-n*f*l-o*r*v+n*c*v)*B,e[3]=(u*c*a-o*d*a-u*r*l+n*d*l+o*r*p-n*c*p)*B,e[4]=y*B,e[5]=(h*f*a-m*d*a+m*r*p-t*f*p-h*r*v+t*d*v)*B,e[6]=(m*c*a-s*f*a-m*r*l+t*f*l+s*r*v-t*c*v)*B,e[7]=(s*d*a-h*c*a+h*r*l-t*d*l-s*r*p+t*c*p)*B,e[8]=S*B,e[9]=(m*u*a-h*g*a-m*n*p+t*g*p+h*n*v-t*u*v)*B,e[10]=(s*g*a-m*o*a+m*n*l-t*g*l-s*n*v+t*o*v)*B,e[11]=(h*o*a-s*u*a-h*n*l+t*u*l+s*n*p-t*o*p)*B,e[12]=w*B,e[13]=(h*g*r-m*u*r+m*n*d-t*g*d-h*n*f+t*u*f)*B,e[14]=(m*o*r-s*g*r-m*n*c+t*g*c+s*n*f-t*o*f)*B,e[15]=(s*u*r-h*o*r+h*n*c-t*u*c-s*n*d+t*o*d)*B,this}scale(e){let t=this.elements,n=e.x,r=e.y,a=e.z;return t[0]*=n,t[4]*=r,t[8]*=a,t[1]*=n,t[5]*=r,t[9]*=a,t[2]*=n,t[6]*=r,t[10]*=a,t[3]*=n,t[7]*=r,t[11]*=a,this}getMaxScaleOnAxis(){let e=this.elements,t=e[0]*e[0]+e[1]*e[1]+e[2]*e[2],n=e[4]*e[4]+e[5]*e[5]+e[6]*e[6],r=e[8]*e[8]+e[9]*e[9]+e[10]*e[10];return Math.sqrt(Math.max(t,n,r))}makeTranslation(e,t,n){return e.isVector3?this.set(1,0,0,e.x,0,1,0,e.y,0,0,1,e.z,0,0,0,1):this.set(1,0,0,e,0,1,0,t,0,0,1,n,0,0,0,1),this}makeRotationX(e){let t=Math.cos(e),n=Math.sin(e);return this.set(1,0,0,0,0,t,-n,0,0,n,t,0,0,0,0,1),this}makeRotationY(e){let t=Math.cos(e),n=Math.sin(e);return this.set(t,0,n,0,0,1,0,0,-n,0,t,0,0,0,0,1),this}makeRotationZ(e){let t=Math.cos(e),n=Math.sin(e);return this.set(t,-n,0,0,n,t,0,0,0,0,1,0,0,0,0,1),this}makeRotationAxis(e,t){let n=Math.cos(t),r=Math.sin(t),a=1-n,s=e.x,o=e.y,c=e.z,l=a*s,h=a*o;return this.set(l*s+n,l*o-r*c,l*c+r*o,0,l*o+r*c,h*o+n,h*c-r*s,0,l*c-r*o,h*c+r*s,a*c*c+n,0,0,0,0,1),this}makeScale(e,t,n){return this.set(e,0,0,0,0,t,0,0,0,0,n,0,0,0,0,1),this}makeShear(e,t,n,r,a,s){return this.set(1,n,a,0,e,1,s,0,t,r,1,0,0,0,0,1),this}compose(e,t,n){let r=this.elements,a=t._x,s=t._y,o=t._z,c=t._w,l=a+a,h=s+s,u=o+o,d=a*l,p=a*h,m=a*u,g=s*h,f=s*u,v=o*u,_=c*l,y=c*h,S=c*u,w=n.x,R=n.y,B=n.z;return r[0]=(1-(g+v))*w,r[1]=(p+S)*w,r[2]=(m-y)*w,r[3]=0,r[4]=(p-S)*R,r[5]=(1-(d+v))*R,r[6]=(f+_)*R,r[7]=0,r[8]=(m+y)*B,r[9]=(f-_)*B,r[10]=(1-(d+g))*B,r[11]=0,r[12]=e.x,r[13]=e.y,r[14]=e.z,r[15]=1,this}decompose(e,t,n){let r=this.elements,a=Hr.set(r[0],r[1],r[2]).length(),s=Hr.set(r[4],r[5],r[6]).length(),o=Hr.set(r[8],r[9],r[10]).length();this.determinant()<0&&(a=-a),e.x=r[12],e.y=r[13],e.z=r[14],Gn.copy(this);let c=1/a,l=1/s,h=1/o;return Gn.elements[0]*=c,Gn.elements[1]*=c,Gn.elements[2]*=c,Gn.elements[4]*=l,Gn.elements[5]*=l,Gn.elements[6]*=l,Gn.elements[8]*=h,Gn.elements[9]*=h,Gn.elements[10]*=h,t.setFromRotationMatrix(Gn),n.x=a,n.y=s,n.z=o,this}makePerspective(e,t,n,r,a,s,o=2e3,c=!1){let l=this.elements,h=2*a/(t-e),u=2*a/(n-r),d=(t+e)/(t-e),p=(n+r)/(n-r),m,g;if(c)m=a/(s-a),g=s*a/(s-a);else if(o===Ei)m=-(s+a)/(s-a),g=-2*s*a/(s-a);else{if(o!==Oa)throw new Error("THREE.Matrix4.makePerspective(): Invalid coordinate system: "+o);m=-s/(s-a),g=-s*a/(s-a)}return l[0]=h,l[4]=0,l[8]=d,l[12]=0,l[1]=0,l[5]=u,l[9]=p,l[13]=0,l[2]=0,l[6]=0,l[10]=m,l[14]=g,l[3]=0,l[7]=0,l[11]=-1,l[15]=0,this}makeOrthographic(e,t,n,r,a,s,o=2e3,c=!1){let l=this.elements,h=2/(t-e),u=2/(n-r),d=-(t+e)/(t-e),p=-(n+r)/(n-r),m,g;if(c)m=1/(s-a),g=s/(s-a);else if(o===Ei)m=-2/(s-a),g=-(s+a)/(s-a);else{if(o!==Oa)throw new Error("THREE.Matrix4.makeOrthographic(): Invalid coordinate system: "+o);m=-1/(s-a),g=-a/(s-a)}return l[0]=h,l[4]=0,l[8]=0,l[12]=d,l[1]=0,l[5]=u,l[9]=0,l[13]=p,l[2]=0,l[6]=0,l[10]=m,l[14]=g,l[3]=0,l[7]=0,l[11]=0,l[15]=1,this}equals(e){let t=this.elements,n=e.elements;for(let r=0;r<16;r++)if(t[r]!==n[r])return!1;return!0}fromArray(e,t=0){for(let n=0;n<16;n++)this.elements[n]=e[n+t];return this}toArray(e=[],t=0){let n=this.elements;return e[t]=n[0],e[t+1]=n[1],e[t+2]=n[2],e[t+3]=n[3],e[t+4]=n[4],e[t+5]=n[5],e[t+6]=n[6],e[t+7]=n[7],e[t+8]=n[8],e[t+9]=n[9],e[t+10]=n[10],e[t+11]=n[11],e[t+12]=n[12],e[t+13]=n[13],e[t+14]=n[14],e[t+15]=n[15],e}},Hr=new E,Gn=new qe,fp=new E(0,0,0),mp=new E(1,1,1),zi=new E,Es=new E,bn=new E,zh=new qe,Hh=new kt,an=class i{constructor(e=0,t=0,n=0,r=i.DEFAULT_ORDER){this.isEuler=!0,this._x=e,this._y=t,this._z=n,this._order=r}get x(){return this._x}set x(e){this._x=e,this._onChangeCallback()}get y(){return this._y}set y(e){this._y=e,this._onChangeCallback()}get z(){return this._z}set z(e){this._z=e,this._onChangeCallback()}get order(){return this._order}set order(e){this._order=e,this._onChangeCallback()}set(e,t,n,r=this._order){return this._x=e,this._y=t,this._z=n,this._order=r,this._onChangeCallback(),this}clone(){return new this.constructor(this._x,this._y,this._z,this._order)}copy(e){return this._x=e._x,this._y=e._y,this._z=e._z,this._order=e._order,this._onChangeCallback(),this}setFromRotationMatrix(e,t=this._order,n=!0){let r=e.elements,a=r[0],s=r[4],o=r[8],c=r[1],l=r[5],h=r[9],u=r[2],d=r[6],p=r[10];switch(t){case"XYZ":this._y=Math.asin(at(o,-1,1)),Math.abs(o)<.9999999?(this._x=Math.atan2(-h,p),this._z=Math.atan2(-s,a)):(this._x=Math.atan2(d,l),this._z=0);break;case"YXZ":this._x=Math.asin(-at(h,-1,1)),Math.abs(h)<.9999999?(this._y=Math.atan2(o,p),this._z=Math.atan2(c,l)):(this._y=Math.atan2(-u,a),this._z=0);break;case"ZXY":this._x=Math.asin(at(d,-1,1)),Math.abs(d)<.9999999?(this._y=Math.atan2(-u,p),this._z=Math.atan2(-s,l)):(this._y=0,this._z=Math.atan2(c,a));break;case"ZYX":this._y=Math.asin(-at(u,-1,1)),Math.abs(u)<.9999999?(this._x=Math.atan2(d,p),this._z=Math.atan2(c,a)):(this._x=0,this._z=Math.atan2(-s,l));break;case"YZX":this._z=Math.asin(at(c,-1,1)),Math.abs(c)<.9999999?(this._x=Math.atan2(-h,l),this._y=Math.atan2(-u,a)):(this._x=0,this._y=Math.atan2(o,p));break;case"XZY":this._z=Math.asin(-at(s,-1,1)),Math.abs(s)<.9999999?(this._x=Math.atan2(d,l),this._y=Math.atan2(o,a)):(this._x=Math.atan2(-h,p),this._y=0);break;default:console.warn("THREE.Euler: .setFromRotationMatrix() encountered an unknown order: "+t)}return this._order=t,n===!0&&this._onChangeCallback(),this}setFromQuaternion(e,t,n){return zh.makeRotationFromQuaternion(e),this.setFromRotationMatrix(zh,t,n)}setFromVector3(e,t=this._order){return this.set(e.x,e.y,e.z,t)}reorder(e){return Hh.setFromEuler(this),this.setFromQuaternion(Hh,e)}equals(e){return e._x===this._x&&e._y===this._y&&e._z===this._z&&e._order===this._order}fromArray(e){return this._x=e[0],this._y=e[1],this._z=e[2],e[3]!==void 0&&(this._order=e[3]),this._onChangeCallback(),this}toArray(e=[],t=0){return e[t]=this._x,e[t+1]=this._y,e[t+2]=this._z,e[t+3]=this._order,e}_onChange(e){return this._onChangeCallback=e,this}_onChangeCallback(){}*[Symbol.iterator](){yield this._x,yield this._y,yield this._z,yield this._order}};an.DEFAULT_ORDER="XYZ";var za=class{constructor(){this.mask=1}set(e){this.mask=1<<e>>>0}enable(e){this.mask|=1<<e}enableAll(){this.mask=-1}toggle(e){this.mask^=1<<e}disable(e){this.mask&=~(1<<e)}disableAll(){this.mask=0}test(e){return(this.mask&e.mask)!==0}isEnabled(e){return!!(this.mask&1<<e)}},gp=0,Gh=new E,Gr=new kt,xi=new qe,ws=new E,Aa=new E,vp=new E,_p=new kt,Vh=new E(1,0,0),Wh=new E(0,1,0),Xh=new E(0,0,1),jh={type:"added"},yp={type:"removed"},Vr={type:"childadded",child:null},Pl={type:"childremoved",child:null},Kt=class i extends wi{constructor(){super(),this.isObject3D=!0,Object.defineProperty(this,"id",{value:gp++}),this.uuid=br(),this.name="",this.type="Object3D",this.parent=null,this.children=[],this.up=i.DEFAULT_UP.clone();let e=new E,t=new an,n=new kt,r=new E(1,1,1);t._onChange(function(){n.setFromEuler(t,!1)}),n._onChange(function(){t.setFromQuaternion(n,void 0,!1)}),Object.defineProperties(this,{position:{configurable:!0,enumerable:!0,value:e},rotation:{configurable:!0,enumerable:!0,value:t},quaternion:{configurable:!0,enumerable:!0,value:n},scale:{configurable:!0,enumerable:!0,value:r},modelViewMatrix:{value:new qe},normalMatrix:{value:new Qe}}),this.matrix=new qe,this.matrixWorld=new qe,this.matrixAutoUpdate=i.DEFAULT_MATRIX_AUTO_UPDATE,this.matrixWorldAutoUpdate=i.DEFAULT_MATRIX_WORLD_AUTO_UPDATE,this.matrixWorldNeedsUpdate=!1,this.layers=new za,this.visible=!0,this.castShadow=!1,this.receiveShadow=!1,this.frustumCulled=!0,this.renderOrder=0,this.animations=[],this.customDepthMaterial=void 0,this.customDistanceMaterial=void 0,this.userData={}}onBeforeShadow(){}onAfterShadow(){}onBeforeRender(){}onAfterRender(){}applyMatrix4(e){this.matrixAutoUpdate&&this.updateMatrix(),this.matrix.premultiply(e),this.matrix.decompose(this.position,this.quaternion,this.scale)}applyQuaternion(e){return this.quaternion.premultiply(e),this}setRotationFromAxisAngle(e,t){this.quaternion.setFromAxisAngle(e,t)}setRotationFromEuler(e){this.quaternion.setFromEuler(e,!0)}setRotationFromMatrix(e){this.quaternion.setFromRotationMatrix(e)}setRotationFromQuaternion(e){this.quaternion.copy(e)}rotateOnAxis(e,t){return Gr.setFromAxisAngle(e,t),this.quaternion.multiply(Gr),this}rotateOnWorldAxis(e,t){return Gr.setFromAxisAngle(e,t),this.quaternion.premultiply(Gr),this}rotateX(e){return this.rotateOnAxis(Vh,e)}rotateY(e){return this.rotateOnAxis(Wh,e)}rotateZ(e){return this.rotateOnAxis(Xh,e)}translateOnAxis(e,t){return Gh.copy(e).applyQuaternion(this.quaternion),this.position.add(Gh.multiplyScalar(t)),this}translateX(e){return this.translateOnAxis(Vh,e)}translateY(e){return this.translateOnAxis(Wh,e)}translateZ(e){return this.translateOnAxis(Xh,e)}localToWorld(e){return this.updateWorldMatrix(!0,!1),e.applyMatrix4(this.matrixWorld)}worldToLocal(e){return this.updateWorldMatrix(!0,!1),e.applyMatrix4(xi.copy(this.matrixWorld).invert())}lookAt(e,t,n){e.isVector3?ws.copy(e):ws.set(e,t,n);let r=this.parent;this.updateWorldMatrix(!0,!1),Aa.setFromMatrixPosition(this.matrixWorld),this.isCamera||this.isLight?xi.lookAt(Aa,ws,this.up):xi.lookAt(ws,Aa,this.up),this.quaternion.setFromRotationMatrix(xi),r&&(xi.extractRotation(r.matrixWorld),Gr.setFromRotationMatrix(xi),this.quaternion.premultiply(Gr.invert()))}add(e){if(arguments.length>1){for(let t=0;t<arguments.length;t++)this.add(arguments[t]);return this}return e===this?(console.error("THREE.Object3D.add: object can't be added as a child of itself.",e),this):(e&&e.isObject3D?(e.removeFromParent(),e.parent=this,this.children.push(e),e.dispatchEvent(jh),Vr.child=e,this.dispatchEvent(Vr),Vr.child=null):console.error("THREE.Object3D.add: object not an instance of THREE.Object3D.",e),this)}remove(e){if(arguments.length>1){for(let n=0;n<arguments.length;n++)this.remove(arguments[n]);return this}let t=this.children.indexOf(e);return t!==-1&&(e.parent=null,this.children.splice(t,1),e.dispatchEvent(yp),Pl.child=e,this.dispatchEvent(Pl),Pl.child=null),this}removeFromParent(){let e=this.parent;return e!==null&&e.remove(this),this}clear(){return this.remove(...this.children)}attach(e){return this.updateWorldMatrix(!0,!1),xi.copy(this.matrixWorld).invert(),e.parent!==null&&(e.parent.updateWorldMatrix(!0,!1),xi.multiply(e.parent.matrixWorld)),e.applyMatrix4(xi),e.removeFromParent(),e.parent=this,this.children.push(e),e.updateWorldMatrix(!1,!0),e.dispatchEvent(jh),Vr.child=e,this.dispatchEvent(Vr),Vr.child=null,this}getObjectById(e){return this.getObjectByProperty("id",e)}getObjectByName(e){return this.getObjectByProperty("name",e)}getObjectByProperty(e,t){if(this[e]===t)return this;for(let n=0,r=this.children.length;n<r;n++){let a=this.children[n].getObjectByProperty(e,t);if(a!==void 0)return a}}getObjectsByProperty(e,t,n=[]){this[e]===t&&n.push(this);let r=this.children;for(let a=0,s=r.length;a<s;a++)r[a].getObjectsByProperty(e,t,n);return n}getWorldPosition(e){return this.updateWorldMatrix(!0,!1),e.setFromMatrixPosition(this.matrixWorld)}getWorldQuaternion(e){return this.updateWorldMatrix(!0,!1),this.matrixWorld.decompose(Aa,e,vp),e}getWorldScale(e){return this.updateWorldMatrix(!0,!1),this.matrixWorld.decompose(Aa,_p,e),e}getWorldDirection(e){this.updateWorldMatrix(!0,!1);let t=this.matrixWorld.elements;return e.set(t[8],t[9],t[10]).normalize()}raycast(){}traverse(e){e(this);let t=this.children;for(let n=0,r=t.length;n<r;n++)t[n].traverse(e)}traverseVisible(e){if(this.visible===!1)return;e(this);let t=this.children;for(let n=0,r=t.length;n<r;n++)t[n].traverseVisible(e)}traverseAncestors(e){let t=this.parent;t!==null&&(e(t),t.traverseAncestors(e))}updateMatrix(){this.matrix.compose(this.position,this.quaternion,this.scale),this.matrixWorldNeedsUpdate=!0}updateMatrixWorld(e){this.matrixAutoUpdate&&this.updateMatrix(),(this.matrixWorldNeedsUpdate||e)&&(this.matrixWorldAutoUpdate===!0&&(this.parent===null?this.matrixWorld.copy(this.matrix):this.matrixWorld.multiplyMatrices(this.parent.matrixWorld,this.matrix)),this.matrixWorldNeedsUpdate=!1,e=!0);let t=this.children;for(let n=0,r=t.length;n<r;n++)t[n].updateMatrixWorld(e)}updateWorldMatrix(e,t){let n=this.parent;if(e===!0&&n!==null&&n.updateWorldMatrix(!0,!1),this.matrixAutoUpdate&&this.updateMatrix(),this.matrixWorldAutoUpdate===!0&&(this.parent===null?this.matrixWorld.copy(this.matrix):this.matrixWorld.multiplyMatrices(this.parent.matrixWorld,this.matrix)),t===!0){let r=this.children;for(let a=0,s=r.length;a<s;a++)r[a].updateWorldMatrix(!1,!0)}}toJSON(e){let t=e===void 0||typeof e=="string",n={};t&&(e={geometries:{},materials:{},textures:{},images:{},shapes:{},skeletons:{},animations:{},nodes:{}},n.metadata={version:4.7,type:"Object",generator:"Object3D.toJSON"});let r={};function a(o,c){return o[c.uuid]===void 0&&(o[c.uuid]=c.toJSON(e)),c.uuid}if(r.uuid=this.uuid,r.type=this.type,this.name!==""&&(r.name=this.name),this.castShadow===!0&&(r.castShadow=!0),this.receiveShadow===!0&&(r.receiveShadow=!0),this.visible===!1&&(r.visible=!1),this.frustumCulled===!1&&(r.frustumCulled=!1),this.renderOrder!==0&&(r.renderOrder=this.renderOrder),Object.keys(this.userData).length>0&&(r.userData=this.userData),r.layers=this.layers.mask,r.matrix=this.matrix.toArray(),r.up=this.up.toArray(),this.matrixAutoUpdate===!1&&(r.matrixAutoUpdate=!1),this.isInstancedMesh&&(r.type="InstancedMesh",r.count=this.count,r.instanceMatrix=this.instanceMatrix.toJSON(),this.instanceColor!==null&&(r.instanceColor=this.instanceColor.toJSON())),this.isBatchedMesh&&(r.type="BatchedMesh",r.perObjectFrustumCulled=this.perObjectFrustumCulled,r.sortObjects=this.sortObjects,r.drawRanges=this._drawRanges,r.reservedRanges=this._reservedRanges,r.geometryInfo=this._geometryInfo.map(o=>({...o,boundingBox:o.boundingBox?o.boundingBox.toJSON():void 0,boundingSphere:o.boundingSphere?o.boundingSphere.toJSON():void 0})),r.instanceInfo=this._instanceInfo.map(o=>({...o})),r.availableInstanceIds=this._availableInstanceIds.slice(),r.availableGeometryIds=this._availableGeometryIds.slice(),r.nextIndexStart=this._nextIndexStart,r.nextVertexStart=this._nextVertexStart,r.geometryCount=this._geometryCount,r.maxInstanceCount=this._maxInstanceCount,r.maxVertexCount=this._maxVertexCount,r.maxIndexCount=this._maxIndexCount,r.geometryInitialized=this._geometryInitialized,r.matricesTexture=this._matricesTexture.toJSON(e),r.indirectTexture=this._indirectTexture.toJSON(e),this._colorsTexture!==null&&(r.colorsTexture=this._colorsTexture.toJSON(e)),this.boundingSphere!==null&&(r.boundingSphere=this.boundingSphere.toJSON()),this.boundingBox!==null&&(r.boundingBox=this.boundingBox.toJSON())),this.isScene)this.background&&(this.background.isColor?r.background=this.background.toJSON():this.background.isTexture&&(r.background=this.background.toJSON(e).uuid)),this.environment&&this.environment.isTexture&&this.environment.isRenderTargetTexture!==!0&&(r.environment=this.environment.toJSON(e).uuid);else if(this.isMesh||this.isLine||this.isPoints){r.geometry=a(e.geometries,this.geometry);let o=this.geometry.parameters;if(o!==void 0&&o.shapes!==void 0){let c=o.shapes;if(Array.isArray(c))for(let l=0,h=c.length;l<h;l++){let u=c[l];a(e.shapes,u)}else a(e.shapes,c)}}if(this.isSkinnedMesh&&(r.bindMode=this.bindMode,r.bindMatrix=this.bindMatrix.toArray(),this.skeleton!==void 0&&(a(e.skeletons,this.skeleton),r.skeleton=this.skeleton.uuid)),this.material!==void 0)if(Array.isArray(this.material)){let o=[];for(let c=0,l=this.material.length;c<l;c++)o.push(a(e.materials,this.material[c]));r.material=o}else r.material=a(e.materials,this.material);if(this.children.length>0){r.children=[];for(let o=0;o<this.children.length;o++)r.children.push(this.children[o].toJSON(e).object)}if(this.animations.length>0){r.animations=[];for(let o=0;o<this.animations.length;o++){let c=this.animations[o];r.animations.push(a(e.animations,c))}}if(t){let o=s(e.geometries),c=s(e.materials),l=s(e.textures),h=s(e.images),u=s(e.shapes),d=s(e.skeletons),p=s(e.animations),m=s(e.nodes);o.length>0&&(n.geometries=o),c.length>0&&(n.materials=c),l.length>0&&(n.textures=l),h.length>0&&(n.images=h),u.length>0&&(n.shapes=u),d.length>0&&(n.skeletons=d),p.length>0&&(n.animations=p),m.length>0&&(n.nodes=m)}return n.object=r,n;function s(o){let c=[];for(let l in o){let h=o[l];delete h.metadata,c.push(h)}return c}}clone(e){return new this.constructor().copy(this,e)}copy(e,t=!0){if(this.name=e.name,this.up.copy(e.up),this.position.copy(e.position),this.rotation.order=e.rotation.order,this.quaternion.copy(e.quaternion),this.scale.copy(e.scale),this.matrix.copy(e.matrix),this.matrixWorld.copy(e.matrixWorld),this.matrixAutoUpdate=e.matrixAutoUpdate,this.matrixWorldAutoUpdate=e.matrixWorldAutoUpdate,this.matrixWorldNeedsUpdate=e.matrixWorldNeedsUpdate,this.layers.mask=e.layers.mask,this.visible=e.visible,this.castShadow=e.castShadow,this.receiveShadow=e.receiveShadow,this.frustumCulled=e.frustumCulled,this.renderOrder=e.renderOrder,this.animations=e.animations.slice(),this.userData=JSON.parse(JSON.stringify(e.userData)),t===!0)for(let n=0;n<e.children.length;n++){let r=e.children[n];this.add(r.clone())}return this}};Kt.DEFAULT_UP=new E(0,1,0),Kt.DEFAULT_MATRIX_AUTO_UPDATE=!0,Kt.DEFAULT_MATRIX_WORLD_AUTO_UPDATE=!0;var Vn=new E,Mi=new E,Il=new E,Si=new E,Wr=new E,Xr=new E,qh=new E,Ll=new E,Dl=new E,Ul=new E,Nl=new xt,Fl=new xt,Ol=new xt,bi=class i{constructor(e=new E,t=new E,n=new E){this.a=e,this.b=t,this.c=n}static getNormal(e,t,n,r){r.subVectors(n,t),Vn.subVectors(e,t),r.cross(Vn);let a=r.lengthSq();return a>0?r.multiplyScalar(1/Math.sqrt(a)):r.set(0,0,0)}static getBarycoord(e,t,n,r,a){Vn.subVectors(r,t),Mi.subVectors(n,t),Il.subVectors(e,t);let s=Vn.dot(Vn),o=Vn.dot(Mi),c=Vn.dot(Il),l=Mi.dot(Mi),h=Mi.dot(Il),u=s*l-o*o;if(u===0)return a.set(0,0,0),null;let d=1/u,p=(l*c-o*h)*d,m=(s*h-o*c)*d;return a.set(1-p-m,m,p)}static containsPoint(e,t,n,r){return this.getBarycoord(e,t,n,r,Si)!==null&&Si.x>=0&&Si.y>=0&&Si.x+Si.y<=1}static getInterpolation(e,t,n,r,a,s,o,c){return this.getBarycoord(e,t,n,r,Si)===null?(c.x=0,c.y=0,"z"in c&&(c.z=0),"w"in c&&(c.w=0),null):(c.setScalar(0),c.addScaledVector(a,Si.x),c.addScaledVector(s,Si.y),c.addScaledVector(o,Si.z),c)}static getInterpolatedAttribute(e,t,n,r,a,s){return Nl.setScalar(0),Fl.setScalar(0),Ol.setScalar(0),Nl.fromBufferAttribute(e,t),Fl.fromBufferAttribute(e,n),Ol.fromBufferAttribute(e,r),s.setScalar(0),s.addScaledVector(Nl,a.x),s.addScaledVector(Fl,a.y),s.addScaledVector(Ol,a.z),s}static isFrontFacing(e,t,n,r){return Vn.subVectors(n,t),Mi.subVectors(e,t),Vn.cross(Mi).dot(r)<0}set(e,t,n){return this.a.copy(e),this.b.copy(t),this.c.copy(n),this}setFromPointsAndIndices(e,t,n,r){return this.a.copy(e[t]),this.b.copy(e[n]),this.c.copy(e[r]),this}setFromAttributeAndIndices(e,t,n,r){return this.a.fromBufferAttribute(e,t),this.b.fromBufferAttribute(e,n),this.c.fromBufferAttribute(e,r),this}clone(){return new this.constructor().copy(this)}copy(e){return this.a.copy(e.a),this.b.copy(e.b),this.c.copy(e.c),this}getArea(){return Vn.subVectors(this.c,this.b),Mi.subVectors(this.a,this.b),.5*Vn.cross(Mi).length()}getMidpoint(e){return e.addVectors(this.a,this.b).add(this.c).multiplyScalar(1/3)}getNormal(e){return i.getNormal(this.a,this.b,this.c,e)}getPlane(e){return e.setFromCoplanarPoints(this.a,this.b,this.c)}getBarycoord(e,t){return i.getBarycoord(e,this.a,this.b,this.c,t)}getInterpolation(e,t,n,r,a){return i.getInterpolation(e,this.a,this.b,this.c,t,n,r,a)}containsPoint(e){return i.containsPoint(e,this.a,this.b,this.c)}isFrontFacing(e){return i.isFrontFacing(this.a,this.b,this.c,e)}intersectsBox(e){return e.intersectsTriangle(this)}closestPointToPoint(e,t){let n=this.a,r=this.b,a=this.c,s,o;Wr.subVectors(r,n),Xr.subVectors(a,n),Ll.subVectors(e,n);let c=Wr.dot(Ll),l=Xr.dot(Ll);if(c<=0&&l<=0)return t.copy(n);Dl.subVectors(e,r);let h=Wr.dot(Dl),u=Xr.dot(Dl);if(h>=0&&u<=h)return t.copy(r);let d=c*u-h*l;if(d<=0&&c>=0&&h<=0)return s=c/(c-h),t.copy(n).addScaledVector(Wr,s);Ul.subVectors(e,a);let p=Wr.dot(Ul),m=Xr.dot(Ul);if(m>=0&&p<=m)return t.copy(a);let g=p*l-c*m;if(g<=0&&l>=0&&m<=0)return o=l/(l-m),t.copy(n).addScaledVector(Xr,o);let f=h*m-p*u;if(f<=0&&u-h>=0&&p-m>=0)return qh.subVectors(a,r),o=(u-h)/(u-h+(p-m)),t.copy(r).addScaledVector(qh,o);let v=1/(f+g+d);return s=g*v,o=d*v,t.copy(n).addScaledVector(Wr,s).addScaledVector(Xr,o)}equals(e){return e.a.equals(this.a)&&e.b.equals(this.b)&&e.c.equals(this.c)}},ad={aliceblue:15792383,antiquewhite:16444375,aqua:65535,aquamarine:8388564,azure:15794175,beige:16119260,bisque:16770244,black:0,blanchedalmond:16772045,blue:255,blueviolet:9055202,brown:10824234,burlywood:14596231,cadetblue:6266528,chartreuse:8388352,chocolate:13789470,coral:16744272,cornflowerblue:6591981,cornsilk:16775388,crimson:14423100,cyan:65535,darkblue:139,darkcyan:35723,darkgoldenrod:12092939,darkgray:11119017,darkgreen:25600,darkgrey:11119017,darkkhaki:12433259,darkmagenta:9109643,darkolivegreen:5597999,darkorange:16747520,darkorchid:10040012,darkred:9109504,darksalmon:15308410,darkseagreen:9419919,darkslateblue:4734347,darkslategray:3100495,darkslategrey:3100495,darkturquoise:52945,darkviolet:9699539,deeppink:16716947,deepskyblue:49151,dimgray:6908265,dimgrey:6908265,dodgerblue:2003199,firebrick:11674146,floralwhite:16775920,forestgreen:2263842,fuchsia:16711935,gainsboro:14474460,ghostwhite:16316671,gold:16766720,goldenrod:14329120,gray:8421504,green:32768,greenyellow:11403055,grey:8421504,honeydew:15794160,hotpink:16738740,indianred:13458524,indigo:4915330,ivory:16777200,khaki:15787660,lavender:15132410,lavenderblush:16773365,lawngreen:8190976,lemonchiffon:16775885,lightblue:11393254,lightcoral:15761536,lightcyan:14745599,lightgoldenrodyellow:16448210,lightgray:13882323,lightgreen:9498256,lightgrey:13882323,lightpink:16758465,lightsalmon:16752762,lightseagreen:2142890,lightskyblue:8900346,lightslategray:7833753,lightslategrey:7833753,lightsteelblue:11584734,lightyellow:16777184,lime:65280,limegreen:3329330,linen:16445670,magenta:16711935,maroon:8388608,mediumaquamarine:6737322,mediumblue:205,mediumorchid:12211667,mediumpurple:9662683,mediumseagreen:3978097,mediumslateblue:8087790,mediumspringgreen:64154,mediumturquoise:4772300,mediumvioletred:13047173,midnightblue:1644912,mintcream:16121850,mistyrose:16770273,moccasin:16770229,navajowhite:16768685,navy:128,oldlace:16643558,olive:8421376,olivedrab:7048739,orange:16753920,orangered:16729344,orchid:14315734,palegoldenrod:15657130,palegreen:10025880,paleturquoise:11529966,palevioletred:14381203,papayawhip:16773077,peachpuff:16767673,peru:13468991,pink:16761035,plum:14524637,powderblue:11591910,purple:8388736,rebeccapurple:6697881,red:16711680,rosybrown:12357519,royalblue:4286945,saddlebrown:9127187,salmon:16416882,sandybrown:16032864,seagreen:3050327,seashell:16774638,sienna:10506797,silver:12632256,skyblue:8900331,slateblue:6970061,slategray:7372944,slategrey:7372944,snow:16775930,springgreen:65407,steelblue:4620980,tan:13808780,teal:32896,thistle:14204888,tomato:16737095,turquoise:4251856,violet:15631086,wheat:16113331,white:16777215,whitesmoke:16119285,yellow:16776960,yellowgreen:10145074},Hi={h:0,s:0,l:0},As={h:0,s:0,l:0};function Bl(i,e,t){return t<0&&(t+=1),t>1&&(t-=1),t<1/6?i+6*(e-i)*t:t<.5?e:t<2/3?i+6*(e-i)*(2/3-t):i}var Ve=class{constructor(e,t,n){return this.isColor=!0,this.r=1,this.g=1,this.b=1,this.set(e,t,n)}set(e,t,n){if(t===void 0&&n===void 0){let r=e;r&&r.isColor?this.copy(r):typeof r=="number"?this.setHex(r):typeof r=="string"&&this.setStyle(r)}else this.setRGB(e,t,n);return this}setScalar(e){return this.r=e,this.g=e,this.b=e,this}setHex(e,t=Wt){return e=Math.floor(e),this.r=(e>>16&255)/255,this.g=(e>>8&255)/255,this.b=(255&e)/255,ht.colorSpaceToWorking(this,t),this}setRGB(e,t,n,r=ht.workingColorSpace){return this.r=e,this.g=t,this.b=n,ht.colorSpaceToWorking(this,r),this}setHSL(e,t,n,r=ht.workingColorSpace){if(e=$l(e,1),t=at(t,0,1),n=at(n,0,1),t===0)this.r=this.g=this.b=n;else{let a=n<=.5?n*(1+t):n+t-n*t,s=2*n-a;this.r=Bl(s,a,e+1/3),this.g=Bl(s,a,e),this.b=Bl(s,a,e-1/3)}return ht.colorSpaceToWorking(this,r),this}setStyle(e,t=Wt){function n(a){a!==void 0&&parseFloat(a)<1&&console.warn("THREE.Color: Alpha component of "+e+" will be ignored.")}let r;if(r=/^(\w+)\(([^\)]*)\)/.exec(e)){let a,s=r[1],o=r[2];switch(s){case"rgb":case"rgba":if(a=/^\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(o))return n(a[4]),this.setRGB(Math.min(255,parseInt(a[1],10))/255,Math.min(255,parseInt(a[2],10))/255,Math.min(255,parseInt(a[3],10))/255,t);if(a=/^\s*(\d+)\%\s*,\s*(\d+)\%\s*,\s*(\d+)\%\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(o))return n(a[4]),this.setRGB(Math.min(100,parseInt(a[1],10))/100,Math.min(100,parseInt(a[2],10))/100,Math.min(100,parseInt(a[3],10))/100,t);break;case"hsl":case"hsla":if(a=/^\s*(\d*\.?\d+)\s*,\s*(\d*\.?\d+)\%\s*,\s*(\d*\.?\d+)\%\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(o))return n(a[4]),this.setHSL(parseFloat(a[1])/360,parseFloat(a[2])/100,parseFloat(a[3])/100,t);break;default:console.warn("THREE.Color: Unknown color model "+e)}}else if(r=/^\#([A-Fa-f\d]+)$/.exec(e)){let a=r[1],s=a.length;if(s===3)return this.setRGB(parseInt(a.charAt(0),16)/15,parseInt(a.charAt(1),16)/15,parseInt(a.charAt(2),16)/15,t);if(s===6)return this.setHex(parseInt(a,16),t);console.warn("THREE.Color: Invalid hex color "+e)}else if(e&&e.length>0)return this.setColorName(e,t);return this}setColorName(e,t=Wt){let n=ad[e.toLowerCase()];return n!==void 0?this.setHex(n,t):console.warn("THREE.Color: Unknown color "+e),this}clone(){return new this.constructor(this.r,this.g,this.b)}copy(e){return this.r=e.r,this.g=e.g,this.b=e.b,this}copySRGBToLinear(e){return this.r=Ti(e.r),this.g=Ti(e.g),this.b=Ti(e.b),this}copyLinearToSRGB(e){return this.r=Kr(e.r),this.g=Kr(e.g),this.b=Kr(e.b),this}convertSRGBToLinear(){return this.copySRGBToLinear(this),this}convertLinearToSRGB(){return this.copyLinearToSRGB(this),this}getHex(e=Wt){return ht.workingToColorSpace(nn.copy(this),e),65536*Math.round(at(255*nn.r,0,255))+256*Math.round(at(255*nn.g,0,255))+Math.round(at(255*nn.b,0,255))}getHexString(e=Wt){return("000000"+this.getHex(e).toString(16)).slice(-6)}getHSL(e,t=ht.workingColorSpace){ht.workingToColorSpace(nn.copy(this),t);let n=nn.r,r=nn.g,a=nn.b,s=Math.max(n,r,a),o=Math.min(n,r,a),c,l,h=(o+s)/2;if(o===s)c=0,l=0;else{let u=s-o;switch(l=h<=.5?u/(s+o):u/(2-s-o),s){case n:c=(r-a)/u+(r<a?6:0);break;case r:c=(a-n)/u+2;break;case a:c=(n-r)/u+4}c/=6}return e.h=c,e.s=l,e.l=h,e}getRGB(e,t=ht.workingColorSpace){return ht.workingToColorSpace(nn.copy(this),t),e.r=nn.r,e.g=nn.g,e.b=nn.b,e}getStyle(e=Wt){ht.workingToColorSpace(nn.copy(this),e);let t=nn.r,n=nn.g,r=nn.b;return e!==Wt?`color(${e} ${t.toFixed(3)} ${n.toFixed(3)} ${r.toFixed(3)})`:`rgb(${Math.round(255*t)},${Math.round(255*n)},${Math.round(255*r)})`}offsetHSL(e,t,n){return this.getHSL(Hi),this.setHSL(Hi.h+e,Hi.s+t,Hi.l+n)}add(e){return this.r+=e.r,this.g+=e.g,this.b+=e.b,this}addColors(e,t){return this.r=e.r+t.r,this.g=e.g+t.g,this.b=e.b+t.b,this}addScalar(e){return this.r+=e,this.g+=e,this.b+=e,this}sub(e){return this.r=Math.max(0,this.r-e.r),this.g=Math.max(0,this.g-e.g),this.b=Math.max(0,this.b-e.b),this}multiply(e){return this.r*=e.r,this.g*=e.g,this.b*=e.b,this}multiplyScalar(e){return this.r*=e,this.g*=e,this.b*=e,this}lerp(e,t){return this.r+=(e.r-this.r)*t,this.g+=(e.g-this.g)*t,this.b+=(e.b-this.b)*t,this}lerpColors(e,t,n){return this.r=e.r+(t.r-e.r)*n,this.g=e.g+(t.g-e.g)*n,this.b=e.b+(t.b-e.b)*n,this}lerpHSL(e,t){this.getHSL(Hi),e.getHSL(As);let n=La(Hi.h,As.h,t),r=La(Hi.s,As.s,t),a=La(Hi.l,As.l,t);return this.setHSL(n,r,a),this}setFromVector3(e){return this.r=e.x,this.g=e.y,this.b=e.z,this}applyMatrix3(e){let t=this.r,n=this.g,r=this.b,a=e.elements;return this.r=a[0]*t+a[3]*n+a[6]*r,this.g=a[1]*t+a[4]*n+a[7]*r,this.b=a[2]*t+a[5]*n+a[8]*r,this}equals(e){return e.r===this.r&&e.g===this.g&&e.b===this.b}fromArray(e,t=0){return this.r=e[t],this.g=e[t+1],this.b=e[t+2],this}toArray(e=[],t=0){return e[t]=this.r,e[t+1]=this.g,e[t+2]=this.b,e}fromBufferAttribute(e,t){return this.r=e.getX(t),this.g=e.getY(t),this.b=e.getZ(t),this}toJSON(){return this.getHex()}*[Symbol.iterator](){yield this.r,yield this.g,yield this.b}},nn=new Ve;Ve.NAMES=ad;var xp=0,Ai=class extends wi{constructor(){super(),this.isMaterial=!0,Object.defineProperty(this,"id",{value:xp++}),this.uuid=br(),this.name="",this.type="Material",this.blending=1,this.side=0,this.vertexColors=!1,this.opacity=1,this.transparent=!1,this.alphaHash=!1,this.blendSrc=204,this.blendDst=205,this.blendEquation=100,this.blendSrcAlpha=null,this.blendDstAlpha=null,this.blendEquationAlpha=null,this.blendColor=new Ve(0,0,0),this.blendAlpha=0,this.depthFunc=3,this.depthTest=!0,this.depthWrite=!0,this.stencilWriteMask=255,this.stencilFunc=519,this.stencilRef=0,this.stencilFuncMask=255,this.stencilFail=dr,this.stencilZFail=dr,this.stencilZPass=dr,this.stencilWrite=!1,this.clippingPlanes=null,this.clipIntersection=!1,this.clipShadows=!1,this.shadowSide=null,this.colorWrite=!0,this.precision=null,this.polygonOffset=!1,this.polygonOffsetFactor=0,this.polygonOffsetUnits=0,this.dithering=!1,this.alphaToCoverage=!1,this.premultipliedAlpha=!1,this.forceSinglePass=!1,this.allowOverride=!0,this.visible=!0,this.toneMapped=!0,this.userData={},this.version=0,this._alphaTest=0}get alphaTest(){return this._alphaTest}set alphaTest(e){this._alphaTest>0!=e>0&&this.version++,this._alphaTest=e}onBeforeRender(){}onBeforeCompile(){}customProgramCacheKey(){return this.onBeforeCompile.toString()}setValues(e){if(e!==void 0)for(let t in e){let n=e[t];if(n===void 0){console.warn(`THREE.Material: parameter '${t}' has value of undefined.`);continue}let r=this[t];r!==void 0?r&&r.isColor?r.set(n):r&&r.isVector3&&n&&n.isVector3?r.copy(n):this[t]=n:console.warn(`THREE.Material: '${t}' is not a property of THREE.${this.type}.`)}}toJSON(e){let t=e===void 0||typeof e=="string";t&&(e={textures:{},images:{}});let n={metadata:{version:4.7,type:"Material",generator:"Material.toJSON"}};function r(a){let s=[];for(let o in a){let c=a[o];delete c.metadata,s.push(c)}return s}if(n.uuid=this.uuid,n.type=this.type,this.name!==""&&(n.name=this.name),this.color&&this.color.isColor&&(n.color=this.color.getHex()),this.roughness!==void 0&&(n.roughness=this.roughness),this.metalness!==void 0&&(n.metalness=this.metalness),this.sheen!==void 0&&(n.sheen=this.sheen),this.sheenColor&&this.sheenColor.isColor&&(n.sheenColor=this.sheenColor.getHex()),this.sheenRoughness!==void 0&&(n.sheenRoughness=this.sheenRoughness),this.emissive&&this.emissive.isColor&&(n.emissive=this.emissive.getHex()),this.emissiveIntensity!==void 0&&this.emissiveIntensity!==1&&(n.emissiveIntensity=this.emissiveIntensity),this.specular&&this.specular.isColor&&(n.specular=this.specular.getHex()),this.specularIntensity!==void 0&&(n.specularIntensity=this.specularIntensity),this.specularColor&&this.specularColor.isColor&&(n.specularColor=this.specularColor.getHex()),this.shininess!==void 0&&(n.shininess=this.shininess),this.clearcoat!==void 0&&(n.clearcoat=this.clearcoat),this.clearcoatRoughness!==void 0&&(n.clearcoatRoughness=this.clearcoatRoughness),this.clearcoatMap&&this.clearcoatMap.isTexture&&(n.clearcoatMap=this.clearcoatMap.toJSON(e).uuid),this.clearcoatRoughnessMap&&this.clearcoatRoughnessMap.isTexture&&(n.clearcoatRoughnessMap=this.clearcoatRoughnessMap.toJSON(e).uuid),this.clearcoatNormalMap&&this.clearcoatNormalMap.isTexture&&(n.clearcoatNormalMap=this.clearcoatNormalMap.toJSON(e).uuid,n.clearcoatNormalScale=this.clearcoatNormalScale.toArray()),this.sheenColorMap&&this.sheenColorMap.isTexture&&(n.sheenColorMap=this.sheenColorMap.toJSON(e).uuid),this.sheenRoughnessMap&&this.sheenRoughnessMap.isTexture&&(n.sheenRoughnessMap=this.sheenRoughnessMap.toJSON(e).uuid),this.dispersion!==void 0&&(n.dispersion=this.dispersion),this.iridescence!==void 0&&(n.iridescence=this.iridescence),this.iridescenceIOR!==void 0&&(n.iridescenceIOR=this.iridescenceIOR),this.iridescenceThicknessRange!==void 0&&(n.iridescenceThicknessRange=this.iridescenceThicknessRange),this.iridescenceMap&&this.iridescenceMap.isTexture&&(n.iridescenceMap=this.iridescenceMap.toJSON(e).uuid),this.iridescenceThicknessMap&&this.iridescenceThicknessMap.isTexture&&(n.iridescenceThicknessMap=this.iridescenceThicknessMap.toJSON(e).uuid),this.anisotropy!==void 0&&(n.anisotropy=this.anisotropy),this.anisotropyRotation!==void 0&&(n.anisotropyRotation=this.anisotropyRotation),this.anisotropyMap&&this.anisotropyMap.isTexture&&(n.anisotropyMap=this.anisotropyMap.toJSON(e).uuid),this.map&&this.map.isTexture&&(n.map=this.map.toJSON(e).uuid),this.matcap&&this.matcap.isTexture&&(n.matcap=this.matcap.toJSON(e).uuid),this.alphaMap&&this.alphaMap.isTexture&&(n.alphaMap=this.alphaMap.toJSON(e).uuid),this.lightMap&&this.lightMap.isTexture&&(n.lightMap=this.lightMap.toJSON(e).uuid,n.lightMapIntensity=this.lightMapIntensity),this.aoMap&&this.aoMap.isTexture&&(n.aoMap=this.aoMap.toJSON(e).uuid,n.aoMapIntensity=this.aoMapIntensity),this.bumpMap&&this.bumpMap.isTexture&&(n.bumpMap=this.bumpMap.toJSON(e).uuid,n.bumpScale=this.bumpScale),this.normalMap&&this.normalMap.isTexture&&(n.normalMap=this.normalMap.toJSON(e).uuid,n.normalMapType=this.normalMapType,n.normalScale=this.normalScale.toArray()),this.displacementMap&&this.displacementMap.isTexture&&(n.displacementMap=this.displacementMap.toJSON(e).uuid,n.displacementScale=this.displacementScale,n.displacementBias=this.displacementBias),this.roughnessMap&&this.roughnessMap.isTexture&&(n.roughnessMap=this.roughnessMap.toJSON(e).uuid),this.metalnessMap&&this.metalnessMap.isTexture&&(n.metalnessMap=this.metalnessMap.toJSON(e).uuid),this.emissiveMap&&this.emissiveMap.isTexture&&(n.emissiveMap=this.emissiveMap.toJSON(e).uuid),this.specularMap&&this.specularMap.isTexture&&(n.specularMap=this.specularMap.toJSON(e).uuid),this.specularIntensityMap&&this.specularIntensityMap.isTexture&&(n.specularIntensityMap=this.specularIntensityMap.toJSON(e).uuid),this.specularColorMap&&this.specularColorMap.isTexture&&(n.specularColorMap=this.specularColorMap.toJSON(e).uuid),this.envMap&&this.envMap.isTexture&&(n.envMap=this.envMap.toJSON(e).uuid,this.combine!==void 0&&(n.combine=this.combine)),this.envMapRotation!==void 0&&(n.envMapRotation=this.envMapRotation.toArray()),this.envMapIntensity!==void 0&&(n.envMapIntensity=this.envMapIntensity),this.reflectivity!==void 0&&(n.reflectivity=this.reflectivity),this.refractionRatio!==void 0&&(n.refractionRatio=this.refractionRatio),this.gradientMap&&this.gradientMap.isTexture&&(n.gradientMap=this.gradientMap.toJSON(e).uuid),this.transmission!==void 0&&(n.transmission=this.transmission),this.transmissionMap&&this.transmissionMap.isTexture&&(n.transmissionMap=this.transmissionMap.toJSON(e).uuid),this.thickness!==void 0&&(n.thickness=this.thickness),this.thicknessMap&&this.thicknessMap.isTexture&&(n.thicknessMap=this.thicknessMap.toJSON(e).uuid),this.attenuationDistance!==void 0&&this.attenuationDistance!==1/0&&(n.attenuationDistance=this.attenuationDistance),this.attenuationColor!==void 0&&(n.attenuationColor=this.attenuationColor.getHex()),this.size!==void 0&&(n.size=this.size),this.shadowSide!==null&&(n.shadowSide=this.shadowSide),this.sizeAttenuation!==void 0&&(n.sizeAttenuation=this.sizeAttenuation),this.blending!==1&&(n.blending=this.blending),this.side!==0&&(n.side=this.side),this.vertexColors===!0&&(n.vertexColors=!0),this.opacity<1&&(n.opacity=this.opacity),this.transparent===!0&&(n.transparent=!0),this.blendSrc!==204&&(n.blendSrc=this.blendSrc),this.blendDst!==205&&(n.blendDst=this.blendDst),this.blendEquation!==100&&(n.blendEquation=this.blendEquation),this.blendSrcAlpha!==null&&(n.blendSrcAlpha=this.blendSrcAlpha),this.blendDstAlpha!==null&&(n.blendDstAlpha=this.blendDstAlpha),this.blendEquationAlpha!==null&&(n.blendEquationAlpha=this.blendEquationAlpha),this.blendColor&&this.blendColor.isColor&&(n.blendColor=this.blendColor.getHex()),this.blendAlpha!==0&&(n.blendAlpha=this.blendAlpha),this.depthFunc!==3&&(n.depthFunc=this.depthFunc),this.depthTest===!1&&(n.depthTest=this.depthTest),this.depthWrite===!1&&(n.depthWrite=this.depthWrite),this.colorWrite===!1&&(n.colorWrite=this.colorWrite),this.stencilWriteMask!==255&&(n.stencilWriteMask=this.stencilWriteMask),this.stencilFunc!==519&&(n.stencilFunc=this.stencilFunc),this.stencilRef!==0&&(n.stencilRef=this.stencilRef),this.stencilFuncMask!==255&&(n.stencilFuncMask=this.stencilFuncMask),this.stencilFail!==dr&&(n.stencilFail=this.stencilFail),this.stencilZFail!==dr&&(n.stencilZFail=this.stencilZFail),this.stencilZPass!==dr&&(n.stencilZPass=this.stencilZPass),this.stencilWrite===!0&&(n.stencilWrite=this.stencilWrite),this.rotation!==void 0&&this.rotation!==0&&(n.rotation=this.rotation),this.polygonOffset===!0&&(n.polygonOffset=!0),this.polygonOffsetFactor!==0&&(n.polygonOffsetFactor=this.polygonOffsetFactor),this.polygonOffsetUnits!==0&&(n.polygonOffsetUnits=this.polygonOffsetUnits),this.linewidth!==void 0&&this.linewidth!==1&&(n.linewidth=this.linewidth),this.dashSize!==void 0&&(n.dashSize=this.dashSize),this.gapSize!==void 0&&(n.gapSize=this.gapSize),this.scale!==void 0&&(n.scale=this.scale),this.dithering===!0&&(n.dithering=!0),this.alphaTest>0&&(n.alphaTest=this.alphaTest),this.alphaHash===!0&&(n.alphaHash=!0),this.alphaToCoverage===!0&&(n.alphaToCoverage=!0),this.premultipliedAlpha===!0&&(n.premultipliedAlpha=!0),this.forceSinglePass===!0&&(n.forceSinglePass=!0),this.wireframe===!0&&(n.wireframe=!0),this.wireframeLinewidth>1&&(n.wireframeLinewidth=this.wireframeLinewidth),this.wireframeLinecap!=="round"&&(n.wireframeLinecap=this.wireframeLinecap),this.wireframeLinejoin!=="round"&&(n.wireframeLinejoin=this.wireframeLinejoin),this.flatShading===!0&&(n.flatShading=!0),this.visible===!1&&(n.visible=!1),this.toneMapped===!1&&(n.toneMapped=!1),this.fog===!1&&(n.fog=!1),Object.keys(this.userData).length>0&&(n.userData=this.userData),t){let a=r(e.textures),s=r(e.images);a.length>0&&(n.textures=a),s.length>0&&(n.images=s)}return n}clone(){return new this.constructor().copy(this)}copy(e){this.name=e.name,this.blending=e.blending,this.side=e.side,this.vertexColors=e.vertexColors,this.opacity=e.opacity,this.transparent=e.transparent,this.blendSrc=e.blendSrc,this.blendDst=e.blendDst,this.blendEquation=e.blendEquation,this.blendSrcAlpha=e.blendSrcAlpha,this.blendDstAlpha=e.blendDstAlpha,this.blendEquationAlpha=e.blendEquationAlpha,this.blendColor.copy(e.blendColor),this.blendAlpha=e.blendAlpha,this.depthFunc=e.depthFunc,this.depthTest=e.depthTest,this.depthWrite=e.depthWrite,this.stencilWriteMask=e.stencilWriteMask,this.stencilFunc=e.stencilFunc,this.stencilRef=e.stencilRef,this.stencilFuncMask=e.stencilFuncMask,this.stencilFail=e.stencilFail,this.stencilZFail=e.stencilZFail,this.stencilZPass=e.stencilZPass,this.stencilWrite=e.stencilWrite;let t=e.clippingPlanes,n=null;if(t!==null){let r=t.length;n=new Array(r);for(let a=0;a!==r;++a)n[a]=t[a].clone()}return this.clippingPlanes=n,this.clipIntersection=e.clipIntersection,this.clipShadows=e.clipShadows,this.shadowSide=e.shadowSide,this.colorWrite=e.colorWrite,this.precision=e.precision,this.polygonOffset=e.polygonOffset,this.polygonOffsetFactor=e.polygonOffsetFactor,this.polygonOffsetUnits=e.polygonOffsetUnits,this.dithering=e.dithering,this.alphaTest=e.alphaTest,this.alphaHash=e.alphaHash,this.alphaToCoverage=e.alphaToCoverage,this.premultipliedAlpha=e.premultipliedAlpha,this.forceSinglePass=e.forceSinglePass,this.visible=e.visible,this.toneMapped=e.toneMapped,this.userData=JSON.parse(JSON.stringify(e.userData)),this}dispose(){this.dispatchEvent({type:"dispose"})}set needsUpdate(e){e===!0&&this.version++}},Ft=class extends Ai{constructor(e){super(),this.isMeshBasicMaterial=!0,this.type="MeshBasicMaterial",this.color=new Ve(16777215),this.map=null,this.lightMap=null,this.lightMapIntensity=1,this.aoMap=null,this.aoMapIntensity=1,this.specularMap=null,this.alphaMap=null,this.envMap=null,this.envMapRotation=new an,this.combine=0,this.reflectivity=1,this.refractionRatio=.98,this.wireframe=!1,this.wireframeLinewidth=1,this.wireframeLinecap="round",this.wireframeLinejoin="round",this.fog=!0,this.setValues(e)}copy(e){return super.copy(e),this.color.copy(e.color),this.map=e.map,this.lightMap=e.lightMap,this.lightMapIntensity=e.lightMapIntensity,this.aoMap=e.aoMap,this.aoMapIntensity=e.aoMapIntensity,this.specularMap=e.specularMap,this.alphaMap=e.alphaMap,this.envMap=e.envMap,this.envMapRotation.copy(e.envMapRotation),this.combine=e.combine,this.reflectivity=e.reflectivity,this.refractionRatio=e.refractionRatio,this.wireframe=e.wireframe,this.wireframeLinewidth=e.wireframeLinewidth,this.wireframeLinecap=e.wireframeLinecap,this.wireframeLinejoin=e.wireframeLinejoin,this.fog=e.fog,this}},Xm=Mp();function Mp(){let i=new ArrayBuffer(4),e=new Float32Array(i),t=new Uint32Array(i),n=new Uint32Array(512),r=new Uint32Array(512);for(let c=0;c<256;++c){let l=c-127;l<-27?(n[c]=0,n[256|c]=32768,r[c]=24,r[256|c]=24):l<-14?(n[c]=1024>>-l-14,n[256|c]=1024>>-l-14|32768,r[c]=-l-1,r[256|c]=-l-1):l<=15?(n[c]=l+15<<10,n[256|c]=l+15<<10|32768,r[c]=13,r[256|c]=13):l<128?(n[c]=31744,n[256|c]=64512,r[c]=24,r[256|c]=24):(n[c]=31744,n[256|c]=64512,r[c]=13,r[256|c]=13)}let a=new Uint32Array(2048),s=new Uint32Array(64),o=new Uint32Array(64);for(let c=1;c<1024;++c){let l=c<<13,h=0;for(;!(8388608&l);)l<<=1,h-=8388608;l&=-8388609,h+=947912704,a[c]=l|h}for(let c=1024;c<2048;++c)a[c]=939524096+(c-1024<<13);for(let c=1;c<31;++c)s[c]=c<<23;s[31]=1199570944,s[32]=2147483648;for(let c=33;c<63;++c)s[c]=2147483648+(c-32<<23);s[63]=3347054592;for(let c=1;c<64;++c)c!==32&&(o[c]=1024);return{floatView:e,uint32View:t,baseTable:n,shiftTable:r,mantissaTable:a,exponentTable:s,offsetTable:o}}var Nt=new E,Rs=new pe,Sp=0,pt=class{constructor(e,t,n=!1){if(Array.isArray(e))throw new TypeError("THREE.BufferAttribute: array should be a Typed Array.");this.isBufferAttribute=!0,Object.defineProperty(this,"id",{value:Sp++}),this.name="",this.array=e,this.itemSize=t,this.count=e!==void 0?e.length/t:0,this.normalized=n,this.usage=Kl,this.updateRanges=[],this.gpuType=jn,this.version=0}onUploadCallback(){}set needsUpdate(e){e===!0&&this.version++}setUsage(e){return this.usage=e,this}addUpdateRange(e,t){this.updateRanges.push({start:e,count:t})}clearUpdateRanges(){this.updateRanges.length=0}copy(e){return this.name=e.name,this.array=new e.array.constructor(e.array),this.itemSize=e.itemSize,this.count=e.count,this.normalized=e.normalized,this.usage=e.usage,this.gpuType=e.gpuType,this}copyAt(e,t,n){e*=this.itemSize,n*=t.itemSize;for(let r=0,a=this.itemSize;r<a;r++)this.array[e+r]=t.array[n+r];return this}copyArray(e){return this.array.set(e),this}applyMatrix3(e){if(this.itemSize===2)for(let t=0,n=this.count;t<n;t++)Rs.fromBufferAttribute(this,t),Rs.applyMatrix3(e),this.setXY(t,Rs.x,Rs.y);else if(this.itemSize===3)for(let t=0,n=this.count;t<n;t++)Nt.fromBufferAttribute(this,t),Nt.applyMatrix3(e),this.setXYZ(t,Nt.x,Nt.y,Nt.z);return this}applyMatrix4(e){for(let t=0,n=this.count;t<n;t++)Nt.fromBufferAttribute(this,t),Nt.applyMatrix4(e),this.setXYZ(t,Nt.x,Nt.y,Nt.z);return this}applyNormalMatrix(e){for(let t=0,n=this.count;t<n;t++)Nt.fromBufferAttribute(this,t),Nt.applyNormalMatrix(e),this.setXYZ(t,Nt.x,Nt.y,Nt.z);return this}transformDirection(e){for(let t=0,n=this.count;t<n;t++)Nt.fromBufferAttribute(this,t),Nt.transformDirection(e),this.setXYZ(t,Nt.x,Nt.y,Nt.z);return this}set(e,t=0){return this.array.set(e,t),this}getComponent(e,t){let n=this.array[e*this.itemSize+t];return this.normalized&&(n=Zr(n,this.array)),n}setComponent(e,t,n){return this.normalized&&(n=dn(n,this.array)),this.array[e*this.itemSize+t]=n,this}getX(e){let t=this.array[e*this.itemSize];return this.normalized&&(t=Zr(t,this.array)),t}setX(e,t){return this.normalized&&(t=dn(t,this.array)),this.array[e*this.itemSize]=t,this}getY(e){let t=this.array[e*this.itemSize+1];return this.normalized&&(t=Zr(t,this.array)),t}setY(e,t){return this.normalized&&(t=dn(t,this.array)),this.array[e*this.itemSize+1]=t,this}getZ(e){let t=this.array[e*this.itemSize+2];return this.normalized&&(t=Zr(t,this.array)),t}setZ(e,t){return this.normalized&&(t=dn(t,this.array)),this.array[e*this.itemSize+2]=t,this}getW(e){let t=this.array[e*this.itemSize+3];return this.normalized&&(t=Zr(t,this.array)),t}setW(e,t){return this.normalized&&(t=dn(t,this.array)),this.array[e*this.itemSize+3]=t,this}setXY(e,t,n){return e*=this.itemSize,this.normalized&&(t=dn(t,this.array),n=dn(n,this.array)),this.array[e+0]=t,this.array[e+1]=n,this}setXYZ(e,t,n,r){return e*=this.itemSize,this.normalized&&(t=dn(t,this.array),n=dn(n,this.array),r=dn(r,this.array)),this.array[e+0]=t,this.array[e+1]=n,this.array[e+2]=r,this}setXYZW(e,t,n,r,a){return e*=this.itemSize,this.normalized&&(t=dn(t,this.array),n=dn(n,this.array),r=dn(r,this.array),a=dn(a,this.array)),this.array[e+0]=t,this.array[e+1]=n,this.array[e+2]=r,this.array[e+3]=a,this}onUpload(e){return this.onUploadCallback=e,this}clone(){return new this.constructor(this.array,this.itemSize).copy(this)}toJSON(){let e={itemSize:this.itemSize,type:this.array.constructor.name,array:Array.from(this.array),normalized:this.normalized};return this.name!==""&&(e.name=this.name),this.usage!==Kl&&(e.usage=this.usage),e}};var Ha=class extends pt{constructor(e,t,n){super(new Uint16Array(e),t,n)}};var Ga=class extends pt{constructor(e,t,n){super(new Uint32Array(e),t,n)}};var Ye=class extends pt{constructor(e,t,n){super(new Float32Array(e),t,n)}},bp=0,Un=new qe,kl=new Kt,jr=new E,Tn=new Nn,Ra=new Nn,Vt=new E,mt=class i extends wi{constructor(){super(),this.isBufferGeometry=!0,Object.defineProperty(this,"id",{value:bp++}),this.uuid=br(),this.name="",this.type="BufferGeometry",this.index=null,this.indirect=null,this.attributes={},this.morphAttributes={},this.morphTargetsRelative=!1,this.groups=[],this.boundingBox=null,this.boundingSphere=null,this.drawRange={start:0,count:1/0},this.userData={}}getIndex(){return this.index}setIndex(e){return Array.isArray(e)?this.index=new(Yc(e)?Ga:Ha)(e,1):this.index=e,this}setIndirect(e){return this.indirect=e,this}getIndirect(){return this.indirect}getAttribute(e){return this.attributes[e]}setAttribute(e,t){return this.attributes[e]=t,this}deleteAttribute(e){return delete this.attributes[e],this}hasAttribute(e){return this.attributes[e]!==void 0}addGroup(e,t,n=0){this.groups.push({start:e,count:t,materialIndex:n})}clearGroups(){this.groups=[]}setDrawRange(e,t){this.drawRange.start=e,this.drawRange.count=t}applyMatrix4(e){let t=this.attributes.position;t!==void 0&&(t.applyMatrix4(e),t.needsUpdate=!0);let n=this.attributes.normal;if(n!==void 0){let a=new Qe().getNormalMatrix(e);n.applyNormalMatrix(a),n.needsUpdate=!0}let r=this.attributes.tangent;return r!==void 0&&(r.transformDirection(e),r.needsUpdate=!0),this.boundingBox!==null&&this.computeBoundingBox(),this.boundingSphere!==null&&this.computeBoundingSphere(),this}applyQuaternion(e){return Un.makeRotationFromQuaternion(e),this.applyMatrix4(Un),this}rotateX(e){return Un.makeRotationX(e),this.applyMatrix4(Un),this}rotateY(e){return Un.makeRotationY(e),this.applyMatrix4(Un),this}rotateZ(e){return Un.makeRotationZ(e),this.applyMatrix4(Un),this}translate(e,t,n){return Un.makeTranslation(e,t,n),this.applyMatrix4(Un),this}scale(e,t,n){return Un.makeScale(e,t,n),this.applyMatrix4(Un),this}lookAt(e){return kl.lookAt(e),kl.updateMatrix(),this.applyMatrix4(kl.matrix),this}center(){return this.computeBoundingBox(),this.boundingBox.getCenter(jr).negate(),this.translate(jr.x,jr.y,jr.z),this}setFromPoints(e){let t=this.getAttribute("position");if(t===void 0){let n=[];for(let r=0,a=e.length;r<a;r++){let s=e[r];n.push(s.x,s.y,s.z||0)}this.setAttribute("position",new Ye(n,3))}else{let n=Math.min(e.length,t.count);for(let r=0;r<n;r++){let a=e[r];t.setXYZ(r,a.x,a.y,a.z||0)}e.length>t.count&&console.warn("THREE.BufferGeometry: Buffer size too small for points data. Use .dispose() and create a new geometry."),t.needsUpdate=!0}return this}computeBoundingBox(){this.boundingBox===null&&(this.boundingBox=new Nn);let e=this.attributes.position,t=this.morphAttributes.position;if(e&&e.isGLBufferAttribute)return console.error("THREE.BufferGeometry.computeBoundingBox(): GLBufferAttribute requires a manual bounding box.",this),void this.boundingBox.set(new E(-1/0,-1/0,-1/0),new E(1/0,1/0,1/0));if(e!==void 0){if(this.boundingBox.setFromBufferAttribute(e),t)for(let n=0,r=t.length;n<r;n++){let a=t[n];Tn.setFromBufferAttribute(a),this.morphTargetsRelative?(Vt.addVectors(this.boundingBox.min,Tn.min),this.boundingBox.expandByPoint(Vt),Vt.addVectors(this.boundingBox.max,Tn.max),this.boundingBox.expandByPoint(Vt)):(this.boundingBox.expandByPoint(Tn.min),this.boundingBox.expandByPoint(Tn.max))}}else this.boundingBox.makeEmpty();(isNaN(this.boundingBox.min.x)||isNaN(this.boundingBox.min.y)||isNaN(this.boundingBox.min.z))&&console.error('THREE.BufferGeometry.computeBoundingBox(): Computed min/max have NaN values. The "position" attribute is likely to have NaN values.',this)}computeBoundingSphere(){this.boundingSphere===null&&(this.boundingSphere=new Fn);let e=this.attributes.position,t=this.morphAttributes.position;if(e&&e.isGLBufferAttribute)return console.error("THREE.BufferGeometry.computeBoundingSphere(): GLBufferAttribute requires a manual bounding sphere.",this),void this.boundingSphere.set(new E,1/0);if(e){let n=this.boundingSphere.center;if(Tn.setFromBufferAttribute(e),t)for(let a=0,s=t.length;a<s;a++){let o=t[a];Ra.setFromBufferAttribute(o),this.morphTargetsRelative?(Vt.addVectors(Tn.min,Ra.min),Tn.expandByPoint(Vt),Vt.addVectors(Tn.max,Ra.max),Tn.expandByPoint(Vt)):(Tn.expandByPoint(Ra.min),Tn.expandByPoint(Ra.max))}Tn.getCenter(n);let r=0;for(let a=0,s=e.count;a<s;a++)Vt.fromBufferAttribute(e,a),r=Math.max(r,n.distanceToSquared(Vt));if(t)for(let a=0,s=t.length;a<s;a++){let o=t[a],c=this.morphTargetsRelative;for(let l=0,h=o.count;l<h;l++)Vt.fromBufferAttribute(o,l),c&&(jr.fromBufferAttribute(e,l),Vt.add(jr)),r=Math.max(r,n.distanceToSquared(Vt))}this.boundingSphere.radius=Math.sqrt(r),isNaN(this.boundingSphere.radius)&&console.error('THREE.BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The "position" attribute is likely to have NaN values.',this)}}computeTangents(){let e=this.index,t=this.attributes;if(e===null||t.position===void 0||t.normal===void 0||t.uv===void 0)return void console.error("THREE.BufferGeometry: .computeTangents() failed. Missing required attributes (index, position, normal or uv)");let n=t.position,r=t.normal,a=t.uv;this.hasAttribute("tangent")===!1&&this.setAttribute("tangent",new pt(new Float32Array(4*n.count),4));let s=this.getAttribute("tangent"),o=[],c=[];for(let G=0;G<n.count;G++)o[G]=new E,c[G]=new E;let l=new E,h=new E,u=new E,d=new pe,p=new pe,m=new pe,g=new E,f=new E;function v(G,D,J){l.fromBufferAttribute(n,G),h.fromBufferAttribute(n,D),u.fromBufferAttribute(n,J),d.fromBufferAttribute(a,G),p.fromBufferAttribute(a,D),m.fromBufferAttribute(a,J),h.sub(l),u.sub(l),p.sub(d),m.sub(d);let K=1/(p.x*m.y-m.x*p.y);isFinite(K)&&(g.copy(h).multiplyScalar(m.y).addScaledVector(u,-p.y).multiplyScalar(K),f.copy(u).multiplyScalar(p.x).addScaledVector(h,-m.x).multiplyScalar(K),o[G].add(g),o[D].add(g),o[J].add(g),c[G].add(f),c[D].add(f),c[J].add(f))}let _=this.groups;_.length===0&&(_=[{start:0,count:e.count}]);for(let G=0,D=_.length;G<D;++G){let J=_[G],K=J.start;for(let V=K,se=K+J.count;V<se;V+=3)v(e.getX(V+0),e.getX(V+1),e.getX(V+2))}let y=new E,S=new E,w=new E,R=new E;function B(G){w.fromBufferAttribute(r,G),R.copy(w);let D=o[G];y.copy(D),y.sub(w.multiplyScalar(w.dot(D))).normalize(),S.crossVectors(R,D);let J=S.dot(c[G])<0?-1:1;s.setXYZW(G,y.x,y.y,y.z,J)}for(let G=0,D=_.length;G<D;++G){let J=_[G],K=J.start;for(let V=K,se=K+J.count;V<se;V+=3)B(e.getX(V+0)),B(e.getX(V+1)),B(e.getX(V+2))}}computeVertexNormals(){let e=this.index,t=this.getAttribute("position");if(t!==void 0){let n=this.getAttribute("normal");if(n===void 0)n=new pt(new Float32Array(3*t.count),3),this.setAttribute("normal",n);else for(let d=0,p=n.count;d<p;d++)n.setXYZ(d,0,0,0);let r=new E,a=new E,s=new E,o=new E,c=new E,l=new E,h=new E,u=new E;if(e)for(let d=0,p=e.count;d<p;d+=3){let m=e.getX(d+0),g=e.getX(d+1),f=e.getX(d+2);r.fromBufferAttribute(t,m),a.fromBufferAttribute(t,g),s.fromBufferAttribute(t,f),h.subVectors(s,a),u.subVectors(r,a),h.cross(u),o.fromBufferAttribute(n,m),c.fromBufferAttribute(n,g),l.fromBufferAttribute(n,f),o.add(h),c.add(h),l.add(h),n.setXYZ(m,o.x,o.y,o.z),n.setXYZ(g,c.x,c.y,c.z),n.setXYZ(f,l.x,l.y,l.z)}else for(let d=0,p=t.count;d<p;d+=3)r.fromBufferAttribute(t,d+0),a.fromBufferAttribute(t,d+1),s.fromBufferAttribute(t,d+2),h.subVectors(s,a),u.subVectors(r,a),h.cross(u),n.setXYZ(d+0,h.x,h.y,h.z),n.setXYZ(d+1,h.x,h.y,h.z),n.setXYZ(d+2,h.x,h.y,h.z);this.normalizeNormals(),n.needsUpdate=!0}}normalizeNormals(){let e=this.attributes.normal;for(let t=0,n=e.count;t<n;t++)Vt.fromBufferAttribute(e,t),Vt.normalize(),e.setXYZ(t,Vt.x,Vt.y,Vt.z)}toNonIndexed(){function e(o,c){let l=o.array,h=o.itemSize,u=o.normalized,d=new l.constructor(c.length*h),p=0,m=0;for(let g=0,f=c.length;g<f;g++){p=o.isInterleavedBufferAttribute?c[g]*o.data.stride+o.offset:c[g]*h;for(let v=0;v<h;v++)d[m++]=l[p++]}return new pt(d,h,u)}if(this.index===null)return console.warn("THREE.BufferGeometry.toNonIndexed(): BufferGeometry is already non-indexed."),this;let t=new i,n=this.index.array,r=this.attributes;for(let o in r){let c=e(r[o],n);t.setAttribute(o,c)}let a=this.morphAttributes;for(let o in a){let c=[],l=a[o];for(let h=0,u=l.length;h<u;h++){let d=e(l[h],n);c.push(d)}t.morphAttributes[o]=c}t.morphTargetsRelative=this.morphTargetsRelative;let s=this.groups;for(let o=0,c=s.length;o<c;o++){let l=s[o];t.addGroup(l.start,l.count,l.materialIndex)}return t}toJSON(){let e={metadata:{version:4.7,type:"BufferGeometry",generator:"BufferGeometry.toJSON"}};if(e.uuid=this.uuid,e.type=this.type,this.name!==""&&(e.name=this.name),Object.keys(this.userData).length>0&&(e.userData=this.userData),this.parameters!==void 0){let c=this.parameters;for(let l in c)c[l]!==void 0&&(e[l]=c[l]);return e}e.data={attributes:{}};let t=this.index;t!==null&&(e.data.index={type:t.array.constructor.name,array:Array.prototype.slice.call(t.array)});let n=this.attributes;for(let c in n){let l=n[c];e.data.attributes[c]=l.toJSON(e.data)}let r={},a=!1;for(let c in this.morphAttributes){let l=this.morphAttributes[c],h=[];for(let u=0,d=l.length;u<d;u++){let p=l[u];h.push(p.toJSON(e.data))}h.length>0&&(r[c]=h,a=!0)}a&&(e.data.morphAttributes=r,e.data.morphTargetsRelative=this.morphTargetsRelative);let s=this.groups;s.length>0&&(e.data.groups=JSON.parse(JSON.stringify(s)));let o=this.boundingSphere;return o!==null&&(e.data.boundingSphere=o.toJSON()),e}clone(){return new this.constructor().copy(this)}copy(e){this.index=null,this.attributes={},this.morphAttributes={},this.groups=[],this.boundingBox=null,this.boundingSphere=null;let t={};this.name=e.name;let n=e.index;n!==null&&this.setIndex(n.clone());let r=e.attributes;for(let l in r){let h=r[l];this.setAttribute(l,h.clone(t))}let a=e.morphAttributes;for(let l in a){let h=[],u=a[l];for(let d=0,p=u.length;d<p;d++)h.push(u[d].clone(t));this.morphAttributes[l]=h}this.morphTargetsRelative=e.morphTargetsRelative;let s=e.groups;for(let l=0,h=s.length;l<h;l++){let u=s[l];this.addGroup(u.start,u.count,u.materialIndex)}let o=e.boundingBox;o!==null&&(this.boundingBox=o.clone());let c=e.boundingSphere;return c!==null&&(this.boundingSphere=c.clone()),this.drawRange.start=e.drawRange.start,this.drawRange.count=e.drawRange.count,this.userData=e.userData,this}dispose(){this.dispatchEvent({type:"dispose"})}},Yh=new qe,hr=new fr,Cs=new Fn,Zh=new E,Ps=new E,Is=new E,Ls=new E,zl=new E,Ds=new E,Jh=new E,Us=new E,Le=class extends Kt{constructor(e=new mt,t=new Ft){super(),this.isMesh=!0,this.type="Mesh",this.geometry=e,this.material=t,this.morphTargetDictionary=void 0,this.morphTargetInfluences=void 0,this.count=1,this.updateMorphTargets()}copy(e,t){return super.copy(e,t),e.morphTargetInfluences!==void 0&&(this.morphTargetInfluences=e.morphTargetInfluences.slice()),e.morphTargetDictionary!==void 0&&(this.morphTargetDictionary=Object.assign({},e.morphTargetDictionary)),this.material=Array.isArray(e.material)?e.material.slice():e.material,this.geometry=e.geometry,this}updateMorphTargets(){let e=this.geometry.morphAttributes,t=Object.keys(e);if(t.length>0){let n=e[t[0]];if(n!==void 0){this.morphTargetInfluences=[],this.morphTargetDictionary={};for(let r=0,a=n.length;r<a;r++){let s=n[r].name||String(r);this.morphTargetInfluences.push(0),this.morphTargetDictionary[s]=r}}}}getVertexPosition(e,t){let n=this.geometry,r=n.attributes.position,a=n.morphAttributes.position,s=n.morphTargetsRelative;t.fromBufferAttribute(r,e);let o=this.morphTargetInfluences;if(a&&o){Ds.set(0,0,0);for(let c=0,l=a.length;c<l;c++){let h=o[c],u=a[c];h!==0&&(zl.fromBufferAttribute(u,e),s?Ds.addScaledVector(zl,h):Ds.addScaledVector(zl.sub(t),h))}t.add(Ds)}return t}raycast(e,t){let n=this.geometry,r=this.material,a=this.matrixWorld;if(r!==void 0){if(n.boundingSphere===null&&n.computeBoundingSphere(),Cs.copy(n.boundingSphere),Cs.applyMatrix4(a),hr.copy(e.ray).recast(e.near),Cs.containsPoint(hr.origin)===!1&&(hr.intersectSphere(Cs,Zh)===null||hr.origin.distanceToSquared(Zh)>(e.far-e.near)**2))return;Yh.copy(a).invert(),hr.copy(e.ray).applyMatrix4(Yh),n.boundingBox!==null&&hr.intersectsBox(n.boundingBox)===!1||this._computeIntersections(e,t,hr)}}_computeIntersections(e,t,n){let r,a=this.geometry,s=this.material,o=a.index,c=a.attributes.position,l=a.attributes.uv,h=a.attributes.uv1,u=a.attributes.normal,d=a.groups,p=a.drawRange;if(o!==null)if(Array.isArray(s))for(let m=0,g=d.length;m<g;m++){let f=d[m],v=s[f.materialIndex];for(let _=Math.max(f.start,p.start),y=Math.min(o.count,Math.min(f.start+f.count,p.start+p.count));_<y;_+=3)r=Ns(this,v,e,n,l,h,u,o.getX(_),o.getX(_+1),o.getX(_+2)),r&&(r.faceIndex=Math.floor(_/3),r.face.materialIndex=f.materialIndex,t.push(r))}else for(let m=Math.max(0,p.start),g=Math.min(o.count,p.start+p.count);m<g;m+=3)r=Ns(this,s,e,n,l,h,u,o.getX(m),o.getX(m+1),o.getX(m+2)),r&&(r.faceIndex=Math.floor(m/3),t.push(r));else if(c!==void 0)if(Array.isArray(s))for(let m=0,g=d.length;m<g;m++){let f=d[m],v=s[f.materialIndex];for(let _=Math.max(f.start,p.start),y=Math.min(c.count,Math.min(f.start+f.count,p.start+p.count));_<y;_+=3)r=Ns(this,v,e,n,l,h,u,_,_+1,_+2),r&&(r.faceIndex=Math.floor(_/3),r.face.materialIndex=f.materialIndex,t.push(r))}else for(let m=Math.max(0,p.start),g=Math.min(c.count,p.start+p.count);m<g;m+=3)r=Ns(this,s,e,n,l,h,u,m,m+1,m+2),r&&(r.faceIndex=Math.floor(m/3),t.push(r))}};function Ns(i,e,t,n,r,a,s,o,c,l){i.getVertexPosition(o,Ps),i.getVertexPosition(c,Is),i.getVertexPosition(l,Ls);let h=(function(u,d,p,m,g,f,v,_){let y;if(y=d.side===1?m.intersectTriangle(v,f,g,!0,_):m.intersectTriangle(g,f,v,d.side===0,_),y===null)return null;Us.copy(_),Us.applyMatrix4(u.matrixWorld);let S=p.ray.origin.distanceTo(Us);return S<p.near||S>p.far?null:{distance:S,point:Us.clone(),object:u}})(i,e,t,n,Ps,Is,Ls,Jh);if(h){let u=new E;bi.getBarycoord(Jh,Ps,Is,Ls,u),r&&(h.uv=bi.getInterpolatedAttribute(r,o,c,l,u,new pe)),a&&(h.uv1=bi.getInterpolatedAttribute(a,o,c,l,u,new pe)),s&&(h.normal=bi.getInterpolatedAttribute(s,o,c,l,u,new E),h.normal.dot(n.direction)>0&&h.normal.multiplyScalar(-1));let d={a:o,b:c,c:l,normal:new E,materialIndex:0};bi.getNormal(Ps,Is,Ls,d.normal),h.face=d,h.barycoord=u}return h}var sn=class i extends mt{constructor(e=1,t=1,n=1,r=1,a=1,s=1){super(),this.type="BoxGeometry",this.parameters={width:e,height:t,depth:n,widthSegments:r,heightSegments:a,depthSegments:s};let o=this;r=Math.floor(r),a=Math.floor(a),s=Math.floor(s);let c=[],l=[],h=[],u=[],d=0,p=0;function m(g,f,v,_,y,S,w,R,B,G,D){let J=S/B,K=w/G,V=S/2,se=w/2,X=R/2,ee=B+1,Q=G+1,me=0,ae=0,be=new E;for(let Be=0;Be<Q;Be++){let Ie=Be*K-se;for(let Ne=0;Ne<ee;Ne++){let le=Ne*J-V;be[g]=le*_,be[f]=Ie*y,be[v]=X,l.push(be.x,be.y,be.z),be[g]=0,be[f]=0,be[v]=R>0?1:-1,h.push(be.x,be.y,be.z),u.push(Ne/B),u.push(1-Be/G),me+=1}}for(let Be=0;Be<G;Be++)for(let Ie=0;Ie<B;Ie++){let Ne=d+Ie+ee*Be,le=d+Ie+ee*(Be+1),re=d+(Ie+1)+ee*(Be+1),ne=d+(Ie+1)+ee*Be;c.push(Ne,le,ne),c.push(le,re,ne),ae+=6}o.addGroup(p,ae,D),p+=ae,d+=me}m("z","y","x",-1,-1,n,t,e,s,a,0),m("z","y","x",1,-1,n,t,-e,s,a,1),m("x","z","y",1,1,e,n,t,r,s,2),m("x","z","y",1,-1,e,n,-t,r,s,3),m("x","y","z",1,-1,e,t,n,r,a,4),m("x","y","z",-1,-1,e,t,-n,r,a,5),this.setIndex(c),this.setAttribute("position",new Ye(l,3)),this.setAttribute("normal",new Ye(h,3)),this.setAttribute("uv",new Ye(u,2))}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}static fromJSON(e){return new i(e.width,e.height,e.depth,e.widthSegments,e.heightSegments,e.depthSegments)}};function Tr(i){let e={};for(let t in i){e[t]={};for(let n in i[t]){let r=i[t][n];r&&(r.isColor||r.isMatrix3||r.isMatrix4||r.isVector2||r.isVector3||r.isVector4||r.isTexture||r.isQuaternion)?r.isRenderTargetTexture?(console.warn("UniformsUtils: Textures of render targets cannot be cloned via cloneUniforms() or mergeUniforms()."),e[t][n]=null):e[t][n]=r.clone():Array.isArray(r)?e[t][n]=r.slice():e[t][n]=r}}return e}function ln(i){let e={};for(let t=0;t<i.length;t++){let n=Tr(i[t]);for(let r in n)e[r]=n[r]}return e}function Zc(i){let e=i.getRenderTarget();return e===null?i.outputColorSpace:e.isXRRenderTarget===!0?e.texture.colorSpace:ht.workingColorSpace}var sd={clone:Tr,merge:ln},Dt=class extends Ai{constructor(e){super(),this.isShaderMaterial=!0,this.type="ShaderMaterial",this.defines={},this.uniforms={},this.uniformsGroups=[],this.vertexShader=`void main() {
	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
}`,this.fragmentShader=`void main() {
	gl_FragColor = vec4( 1.0, 0.0, 0.0, 1.0 );
}`,this.linewidth=1,this.wireframe=!1,this.wireframeLinewidth=1,this.fog=!1,this.lights=!1,this.clipping=!1,this.forceSinglePass=!0,this.extensions={clipCullDistance:!1,multiDraw:!1},this.defaultAttributeValues={color:[1,1,1],uv:[0,0],uv1:[0,0]},this.index0AttributeName=void 0,this.uniformsNeedUpdate=!1,this.glslVersion=null,e!==void 0&&this.setValues(e)}copy(e){return super.copy(e),this.fragmentShader=e.fragmentShader,this.vertexShader=e.vertexShader,this.uniforms=Tr(e.uniforms),this.uniformsGroups=(function(t){let n=[];for(let r=0;r<t.length;r++)n.push(t[r].clone());return n})(e.uniformsGroups),this.defines=Object.assign({},e.defines),this.wireframe=e.wireframe,this.wireframeLinewidth=e.wireframeLinewidth,this.fog=e.fog,this.lights=e.lights,this.clipping=e.clipping,this.extensions=Object.assign({},e.extensions),this.glslVersion=e.glslVersion,this}toJSON(e){let t=super.toJSON(e);t.glslVersion=this.glslVersion,t.uniforms={};for(let r in this.uniforms){let a=this.uniforms[r].value;a&&a.isTexture?t.uniforms[r]={type:"t",value:a.toJSON(e).uuid}:a&&a.isColor?t.uniforms[r]={type:"c",value:a.getHex()}:a&&a.isVector2?t.uniforms[r]={type:"v2",value:a.toArray()}:a&&a.isVector3?t.uniforms[r]={type:"v3",value:a.toArray()}:a&&a.isVector4?t.uniforms[r]={type:"v4",value:a.toArray()}:a&&a.isMatrix3?t.uniforms[r]={type:"m3",value:a.toArray()}:a&&a.isMatrix4?t.uniforms[r]={type:"m4",value:a.toArray()}:t.uniforms[r]={value:a}}Object.keys(this.defines).length>0&&(t.defines=this.defines),t.vertexShader=this.vertexShader,t.fragmentShader=this.fragmentShader,t.lights=this.lights,t.clipping=this.clipping;let n={};for(let r in this.extensions)this.extensions[r]===!0&&(n[r]=!0);return Object.keys(n).length>0&&(t.extensions=n),t}},na=class extends Kt{constructor(){super(),this.isCamera=!0,this.type="Camera",this.matrixWorldInverse=new qe,this.projectionMatrix=new qe,this.projectionMatrixInverse=new qe,this.coordinateSystem=Ei,this._reversedDepth=!1}get reversedDepth(){return this._reversedDepth}copy(e,t){return super.copy(e,t),this.matrixWorldInverse.copy(e.matrixWorldInverse),this.projectionMatrix.copy(e.projectionMatrix),this.projectionMatrixInverse.copy(e.projectionMatrixInverse),this.coordinateSystem=e.coordinateSystem,this}getWorldDirection(e){return super.getWorldDirection(e).negate()}updateMatrixWorld(e){super.updateMatrixWorld(e),this.matrixWorldInverse.copy(this.matrixWorld).invert()}updateWorldMatrix(e,t){super.updateWorldMatrix(e,t),this.matrixWorldInverse.copy(this.matrixWorld).invert()}clone(){return new this.constructor().copy(this)}},Gi=new E,Kh=new pe,$h=new pe,rn=class extends na{constructor(e=50,t=1,n=.1,r=2e3){super(),this.isPerspectiveCamera=!0,this.type="PerspectiveCamera",this.fov=e,this.zoom=1,this.near=n,this.far=r,this.focus=10,this.aspect=t,this.view=null,this.filmGauge=35,this.filmOffset=0,this.updateProjectionMatrix()}copy(e,t){return super.copy(e,t),this.fov=e.fov,this.zoom=e.zoom,this.near=e.near,this.far=e.far,this.focus=e.focus,this.aspect=e.aspect,this.view=e.view===null?null:Object.assign({},e.view),this.filmGauge=e.filmGauge,this.filmOffset=e.filmOffset,this}setFocalLength(e){let t=.5*this.getFilmHeight()/e;this.fov=2*Qr*Math.atan(t),this.updateProjectionMatrix()}getFocalLength(){let e=Math.tan(.5*Jr*this.fov);return .5*this.getFilmHeight()/e}getEffectiveFOV(){return 2*Qr*Math.atan(Math.tan(.5*Jr*this.fov)/this.zoom)}getFilmWidth(){return this.filmGauge*Math.min(this.aspect,1)}getFilmHeight(){return this.filmGauge/Math.max(this.aspect,1)}getViewBounds(e,t,n){Gi.set(-1,-1,.5).applyMatrix4(this.projectionMatrixInverse),t.set(Gi.x,Gi.y).multiplyScalar(-e/Gi.z),Gi.set(1,1,.5).applyMatrix4(this.projectionMatrixInverse),n.set(Gi.x,Gi.y).multiplyScalar(-e/Gi.z)}getViewSize(e,t){return this.getViewBounds(e,Kh,$h),t.subVectors($h,Kh)}setViewOffset(e,t,n,r,a,s){this.aspect=e/t,this.view===null&&(this.view={enabled:!0,fullWidth:1,fullHeight:1,offsetX:0,offsetY:0,width:1,height:1}),this.view.enabled=!0,this.view.fullWidth=e,this.view.fullHeight=t,this.view.offsetX=n,this.view.offsetY=r,this.view.width=a,this.view.height=s,this.updateProjectionMatrix()}clearViewOffset(){this.view!==null&&(this.view.enabled=!1),this.updateProjectionMatrix()}updateProjectionMatrix(){let e=this.near,t=e*Math.tan(.5*Jr*this.fov)/this.zoom,n=2*t,r=this.aspect*n,a=-.5*r,s=this.view;if(this.view!==null&&this.view.enabled){let c=s.fullWidth,l=s.fullHeight;a+=s.offsetX*r/c,t-=s.offsetY*n/l,r*=s.width/c,n*=s.height/l}let o=this.filmOffset;o!==0&&(a+=e*o/this.getFilmWidth()),this.projectionMatrix.makePerspective(a,a+r,t,t-n,e,this.far,this.coordinateSystem,this.reversedDepth),this.projectionMatrixInverse.copy(this.projectionMatrix).invert()}toJSON(e){let t=super.toJSON(e);return t.object.fov=this.fov,t.object.zoom=this.zoom,t.object.near=this.near,t.object.far=this.far,t.object.focus=this.focus,t.object.aspect=this.aspect,this.view!==null&&(t.object.view=Object.assign({},this.view)),t.object.filmGauge=this.filmGauge,t.object.filmOffset=this.filmOffset,t}},qr=-90,Qs=class extends Kt{constructor(e,t,n){super(),this.type="CubeCamera",this.renderTarget=n,this.coordinateSystem=null,this.activeMipmapLevel=0;let r=new rn(qr,1,e,t);r.layers=this.layers,this.add(r);let a=new rn(qr,1,e,t);a.layers=this.layers,this.add(a);let s=new rn(qr,1,e,t);s.layers=this.layers,this.add(s);let o=new rn(qr,1,e,t);o.layers=this.layers,this.add(o);let c=new rn(qr,1,e,t);c.layers=this.layers,this.add(c);let l=new rn(qr,1,e,t);l.layers=this.layers,this.add(l)}updateCoordinateSystem(){let e=this.coordinateSystem,t=this.children.concat(),[n,r,a,s,o,c]=t;for(let l of t)this.remove(l);if(e===Ei)n.up.set(0,1,0),n.lookAt(1,0,0),r.up.set(0,1,0),r.lookAt(-1,0,0),a.up.set(0,0,-1),a.lookAt(0,1,0),s.up.set(0,0,1),s.lookAt(0,-1,0),o.up.set(0,1,0),o.lookAt(0,0,1),c.up.set(0,1,0),c.lookAt(0,0,-1);else{if(e!==Oa)throw new Error("THREE.CubeCamera.updateCoordinateSystem(): Invalid coordinate system: "+e);n.up.set(0,-1,0),n.lookAt(-1,0,0),r.up.set(0,-1,0),r.lookAt(1,0,0),a.up.set(0,0,1),a.lookAt(0,1,0),s.up.set(0,0,-1),s.lookAt(0,-1,0),o.up.set(0,-1,0),o.lookAt(0,0,1),c.up.set(0,-1,0),c.lookAt(0,0,-1)}for(let l of t)this.add(l),l.updateMatrixWorld()}update(e,t){this.parent===null&&this.updateMatrixWorld();let{renderTarget:n,activeMipmapLevel:r}=this;this.coordinateSystem!==e.coordinateSystem&&(this.coordinateSystem=e.coordinateSystem,this.updateCoordinateSystem());let[a,s,o,c,l,h]=this.children,u=e.getRenderTarget(),d=e.getActiveCubeFace(),p=e.getActiveMipmapLevel(),m=e.xr.enabled;e.xr.enabled=!1;let g=n.texture.generateMipmaps;n.texture.generateMipmaps=!1,e.setRenderTarget(n,0,r),e.render(t,a),e.setRenderTarget(n,1,r),e.render(t,s),e.setRenderTarget(n,2,r),e.render(t,o),e.setRenderTarget(n,3,r),e.render(t,c),e.setRenderTarget(n,4,r),e.render(t,l),n.texture.generateMipmaps=g,e.setRenderTarget(n,5,r),e.render(t,h),e.setRenderTarget(u,d,p),e.xr.enabled=m,n.texture.needsPMREMUpdate=!0}},Va=class extends fn{constructor(e=[],t=301,n,r,a,s,o,c,l,h){super(e,t,n,r,a,s,o,c,l,h),this.isCubeTexture=!0,this.flipY=!1}get images(){return this.image}set images(e){this.image=e}},eo=class extends yn{constructor(e=1,t={}){super(e,e,t),this.isWebGLCubeRenderTarget=!0;let n={width:e,height:e,depth:1},r=[n,n,n,n,n,n];this.texture=new Va(r),this._setTextureOptions(t),this.texture.isRenderTargetTexture=!0}fromEquirectangularTexture(e,t){this.texture.type=t.type,this.texture.colorSpace=t.colorSpace,this.texture.generateMipmaps=t.generateMipmaps,this.texture.minFilter=t.minFilter,this.texture.magFilter=t.magFilter;let n={uniforms:{tEquirect:{value:null}},vertexShader:`

				varying vec3 vWorldDirection;

				vec3 transformDirection( in vec3 dir, in mat4 matrix ) {

					return normalize( ( matrix * vec4( dir, 0.0 ) ).xyz );

				}

				void main() {

					vWorldDirection = transformDirection( position, modelMatrix );

					#include <begin_vertex>
					#include <project_vertex>

				}
			`,fragmentShader:`

				uniform sampler2D tEquirect;

				varying vec3 vWorldDirection;

				#include <common>

				void main() {

					vec3 direction = normalize( vWorldDirection );

					vec2 sampleUV = equirectUv( direction );

					gl_FragColor = texture2D( tEquirect, sampleUV );

				}
			`},r=new sn(5,5,5),a=new Dt({name:"CubemapFromEquirect",uniforms:Tr(n.uniforms),vertexShader:n.vertexShader,fragmentShader:n.fragmentShader,side:1,blending:0});a.uniforms.tEquirect.value=t;let s=new Le(r,a),o=t.minFilter;return t.minFilter===xr&&(t.minFilter=ri),new Qs(1,10,this).update(e,s),t.minFilter=o,s.geometry.dispose(),s.material.dispose(),this}clear(e,t=!0,n=!0,r=!0){let a=e.getRenderTarget();for(let s=0;s<6;s++)e.setRenderTarget(this,s),e.clear(t,n,r);e.setRenderTarget(a)}},pn=class extends Kt{constructor(){super(),this.isGroup=!0,this.type="Group"}},Tp={type:"move"},ia=class{constructor(){this._targetRay=null,this._grip=null,this._hand=null}getHandSpace(){return this._hand===null&&(this._hand=new pn,this._hand.matrixAutoUpdate=!1,this._hand.visible=!1,this._hand.joints={},this._hand.inputState={pinching:!1}),this._hand}getTargetRaySpace(){return this._targetRay===null&&(this._targetRay=new pn,this._targetRay.matrixAutoUpdate=!1,this._targetRay.visible=!1,this._targetRay.hasLinearVelocity=!1,this._targetRay.linearVelocity=new E,this._targetRay.hasAngularVelocity=!1,this._targetRay.angularVelocity=new E),this._targetRay}getGripSpace(){return this._grip===null&&(this._grip=new pn,this._grip.matrixAutoUpdate=!1,this._grip.visible=!1,this._grip.hasLinearVelocity=!1,this._grip.linearVelocity=new E,this._grip.hasAngularVelocity=!1,this._grip.angularVelocity=new E),this._grip}dispatchEvent(e){return this._targetRay!==null&&this._targetRay.dispatchEvent(e),this._grip!==null&&this._grip.dispatchEvent(e),this._hand!==null&&this._hand.dispatchEvent(e),this}connect(e){if(e&&e.hand){let t=this._hand;if(t)for(let n of e.hand.values())this._getHandJoint(t,n)}return this.dispatchEvent({type:"connected",data:e}),this}disconnect(e){return this.dispatchEvent({type:"disconnected",data:e}),this._targetRay!==null&&(this._targetRay.visible=!1),this._grip!==null&&(this._grip.visible=!1),this._hand!==null&&(this._hand.visible=!1),this}update(e,t,n){let r=null,a=null,s=null,o=this._targetRay,c=this._grip,l=this._hand;if(e&&t.session.visibilityState!=="visible-blurred"){if(l&&e.hand){s=!0;for(let g of e.hand.values()){let f=t.getJointPose(g,n),v=this._getHandJoint(l,g);f!==null&&(v.matrix.fromArray(f.transform.matrix),v.matrix.decompose(v.position,v.rotation,v.scale),v.matrixWorldNeedsUpdate=!0,v.jointRadius=f.radius),v.visible=f!==null}let h=l.joints["index-finger-tip"],u=l.joints["thumb-tip"],d=h.position.distanceTo(u.position),p=.02,m=.005;l.inputState.pinching&&d>p+m?(l.inputState.pinching=!1,this.dispatchEvent({type:"pinchend",handedness:e.handedness,target:this})):!l.inputState.pinching&&d<=p-m&&(l.inputState.pinching=!0,this.dispatchEvent({type:"pinchstart",handedness:e.handedness,target:this}))}else c!==null&&e.gripSpace&&(a=t.getPose(e.gripSpace,n),a!==null&&(c.matrix.fromArray(a.transform.matrix),c.matrix.decompose(c.position,c.rotation,c.scale),c.matrixWorldNeedsUpdate=!0,a.linearVelocity?(c.hasLinearVelocity=!0,c.linearVelocity.copy(a.linearVelocity)):c.hasLinearVelocity=!1,a.angularVelocity?(c.hasAngularVelocity=!0,c.angularVelocity.copy(a.angularVelocity)):c.hasAngularVelocity=!1));o!==null&&(r=t.getPose(e.targetRaySpace,n),r===null&&a!==null&&(r=a),r!==null&&(o.matrix.fromArray(r.transform.matrix),o.matrix.decompose(o.position,o.rotation,o.scale),o.matrixWorldNeedsUpdate=!0,r.linearVelocity?(o.hasLinearVelocity=!0,o.linearVelocity.copy(r.linearVelocity)):o.hasLinearVelocity=!1,r.angularVelocity?(o.hasAngularVelocity=!0,o.angularVelocity.copy(r.angularVelocity)):o.hasAngularVelocity=!1,this.dispatchEvent(Tp)))}return o!==null&&(o.visible=r!==null),c!==null&&(c.visible=a!==null),l!==null&&(l.visible=s!==null),this}_getHandJoint(e,t){if(e.joints[t.jointName]===void 0){let n=new pn;n.matrixAutoUpdate=!1,n.visible=!1,e.joints[t.jointName]=n,e.add(n)}return e.joints[t.jointName]}};var ji=class extends Kt{constructor(){super(),this.isScene=!0,this.type="Scene",this.background=null,this.environment=null,this.fog=null,this.backgroundBlurriness=0,this.backgroundIntensity=1,this.backgroundRotation=new an,this.environmentIntensity=1,this.environmentRotation=new an,this.overrideMaterial=null,typeof __THREE_DEVTOOLS__!="undefined"&&__THREE_DEVTOOLS__.dispatchEvent(new CustomEvent("observe",{detail:this}))}copy(e,t){return super.copy(e,t),e.background!==null&&(this.background=e.background.clone()),e.environment!==null&&(this.environment=e.environment.clone()),e.fog!==null&&(this.fog=e.fog.clone()),this.backgroundBlurriness=e.backgroundBlurriness,this.backgroundIntensity=e.backgroundIntensity,this.backgroundRotation.copy(e.backgroundRotation),this.environmentIntensity=e.environmentIntensity,this.environmentRotation.copy(e.environmentRotation),e.overrideMaterial!==null&&(this.overrideMaterial=e.overrideMaterial.clone()),this.matrixAutoUpdate=e.matrixAutoUpdate,this}toJSON(e){let t=super.toJSON(e);return this.fog!==null&&(t.object.fog=this.fog.toJSON()),this.backgroundBlurriness>0&&(t.object.backgroundBlurriness=this.backgroundBlurriness),this.backgroundIntensity!==1&&(t.object.backgroundIntensity=this.backgroundIntensity),t.object.backgroundRotation=this.backgroundRotation.toArray(),this.environmentIntensity!==1&&(t.object.environmentIntensity=this.environmentIntensity),t.object.environmentRotation=this.environmentRotation.toArray(),t}};var jm=new E;var qm=new E,Ym=new E,Zm=new E,Jm=new pe,Km=new pe,$m=new qe,Qm=new E,e0=new E,t0=new E,n0=new pe,i0=new pe,r0=new pe;var a0=new E,s0=new E;var o0=new E,l0=new xt,c0=new xt,h0=new E,u0=new qe,d0=new E,p0=new Fn,f0=new qe,m0=new fr;var to=class extends fn{constructor(e=null,t=1,n=1,r,a,s,o,c,l=1003,h=1003,u,d){super(null,s,o,c,l,h,r,a,u,d),this.isDataTexture=!0,this.image={data:e,width:t,height:n},this.generateMipmaps=!1,this.flipY=!1,this.unpackAlignment=1}},g0=new qe,v0=new qe;var Wa=class extends pt{constructor(e,t,n,r=1){super(e,t,n),this.isInstancedBufferAttribute=!0,this.meshPerAttribute=r}copy(e){return super.copy(e),this.meshPerAttribute=e.meshPerAttribute,this}toJSON(){let e=super.toJSON();return e.meshPerAttribute=this.meshPerAttribute,e.isInstancedBufferAttribute=!0,e}},Yr=new qe,Qh=new qe,Fs=[],eu=new Nn,Ep=new qe,Ca=new Le,Pa=new Fn,ai=class extends Le{constructor(e,t,n){super(e,t),this.isInstancedMesh=!0,this.instanceMatrix=new Wa(new Float32Array(16*n),16),this.instanceColor=null,this.morphTexture=null,this.count=n,this.boundingBox=null,this.boundingSphere=null;for(let r=0;r<n;r++)this.setMatrixAt(r,Ep)}computeBoundingBox(){let e=this.geometry,t=this.count;this.boundingBox===null&&(this.boundingBox=new Nn),e.boundingBox===null&&e.computeBoundingBox(),this.boundingBox.makeEmpty();for(let n=0;n<t;n++)this.getMatrixAt(n,Yr),eu.copy(e.boundingBox).applyMatrix4(Yr),this.boundingBox.union(eu)}computeBoundingSphere(){let e=this.geometry,t=this.count;this.boundingSphere===null&&(this.boundingSphere=new Fn),e.boundingSphere===null&&e.computeBoundingSphere(),this.boundingSphere.makeEmpty();for(let n=0;n<t;n++)this.getMatrixAt(n,Yr),Pa.copy(e.boundingSphere).applyMatrix4(Yr),this.boundingSphere.union(Pa)}copy(e,t){return super.copy(e,t),this.instanceMatrix.copy(e.instanceMatrix),e.morphTexture!==null&&(this.morphTexture=e.morphTexture.clone()),e.instanceColor!==null&&(this.instanceColor=e.instanceColor.clone()),this.count=e.count,e.boundingBox!==null&&(this.boundingBox=e.boundingBox.clone()),e.boundingSphere!==null&&(this.boundingSphere=e.boundingSphere.clone()),this}getColorAt(e,t){t.fromArray(this.instanceColor.array,3*e)}getMatrixAt(e,t){t.fromArray(this.instanceMatrix.array,16*e)}getMorphAt(e,t){let n=t.morphTargetInfluences,r=this.morphTexture.source.data.data,a=e*(n.length+1)+1;for(let s=0;s<n.length;s++)n[s]=r[a+s]}raycast(e,t){let n=this.matrixWorld,r=this.count;if(Ca.geometry=this.geometry,Ca.material=this.material,Ca.material!==void 0&&(this.boundingSphere===null&&this.computeBoundingSphere(),Pa.copy(this.boundingSphere),Pa.applyMatrix4(n),e.ray.intersectsSphere(Pa)!==!1))for(let a=0;a<r;a++){this.getMatrixAt(a,Yr),Qh.multiplyMatrices(n,Yr),Ca.matrixWorld=Qh,Ca.raycast(e,Fs);for(let s=0,o=Fs.length;s<o;s++){let c=Fs[s];c.instanceId=a,c.object=this,t.push(c)}Fs.length=0}}setColorAt(e,t){this.instanceColor===null&&(this.instanceColor=new Wa(new Float32Array(3*this.instanceMatrix.count).fill(1),3)),t.toArray(this.instanceColor.array,3*e)}setMatrixAt(e,t){t.toArray(this.instanceMatrix.array,16*e)}setMorphAt(e,t){let n=t.morphTargetInfluences,r=n.length+1;this.morphTexture===null&&(this.morphTexture=new to(new Float32Array(r*this.count),r,this.count,Jo,jn));let a=this.morphTexture.source.data.data,s=0;for(let l=0;l<n.length;l++)s+=n[l];let o=this.geometry.morphTargetsRelative?1:1-s,c=r*e;a[c]=o,a.set(n,c+1)}updateMorphTargets(){}dispose(){this.dispatchEvent({type:"dispose"}),this.morphTexture!==null&&(this.morphTexture.dispose(),this.morphTexture=null)}},Hl=new E,wp=new E,Ap=new Qe,ti=class{constructor(e=new E(1,0,0),t=0){this.isPlane=!0,this.normal=e,this.constant=t}set(e,t){return this.normal.copy(e),this.constant=t,this}setComponents(e,t,n,r){return this.normal.set(e,t,n),this.constant=r,this}setFromNormalAndCoplanarPoint(e,t){return this.normal.copy(e),this.constant=-t.dot(this.normal),this}setFromCoplanarPoints(e,t,n){let r=Hl.subVectors(n,t).cross(wp.subVectors(e,t)).normalize();return this.setFromNormalAndCoplanarPoint(r,e),this}copy(e){return this.normal.copy(e.normal),this.constant=e.constant,this}normalize(){let e=1/this.normal.length();return this.normal.multiplyScalar(e),this.constant*=e,this}negate(){return this.constant*=-1,this.normal.negate(),this}distanceToPoint(e){return this.normal.dot(e)+this.constant}distanceToSphere(e){return this.distanceToPoint(e.center)-e.radius}projectPoint(e,t){return t.copy(e).addScaledVector(this.normal,-this.distanceToPoint(e))}intersectLine(e,t){let n=e.delta(Hl),r=this.normal.dot(n);if(r===0)return this.distanceToPoint(e.start)===0?t.copy(e.start):null;let a=-(e.start.dot(this.normal)+this.constant)/r;return a<0||a>1?null:t.copy(e.start).addScaledVector(n,a)}intersectsLine(e){let t=this.distanceToPoint(e.start),n=this.distanceToPoint(e.end);return t<0&&n>0||n<0&&t>0}intersectsBox(e){return e.intersectsPlane(this)}intersectsSphere(e){return e.intersectsPlane(this)}coplanarPoint(e){return e.copy(this.normal).multiplyScalar(-this.constant)}applyMatrix4(e,t){let n=t||Ap.getNormalMatrix(e),r=this.coplanarPoint(Hl).applyMatrix4(e),a=this.normal.applyMatrix3(n).normalize();return this.constant=-r.dot(a),this}translate(e){return this.constant-=e.dot(this.normal),this}equals(e){return e.normal.equals(this.normal)&&e.constant===this.constant}clone(){return new this.constructor().copy(this)}},ur=new Fn,Rp=new pe(.5,.5),Os=new E,qi=class{constructor(e=new ti,t=new ti,n=new ti,r=new ti,a=new ti,s=new ti){this.planes=[e,t,n,r,a,s]}set(e,t,n,r,a,s){let o=this.planes;return o[0].copy(e),o[1].copy(t),o[2].copy(n),o[3].copy(r),o[4].copy(a),o[5].copy(s),this}copy(e){let t=this.planes;for(let n=0;n<6;n++)t[n].copy(e.planes[n]);return this}setFromProjectionMatrix(e,t=2e3,n=!1){let r=this.planes,a=e.elements,s=a[0],o=a[1],c=a[2],l=a[3],h=a[4],u=a[5],d=a[6],p=a[7],m=a[8],g=a[9],f=a[10],v=a[11],_=a[12],y=a[13],S=a[14],w=a[15];if(r[0].setComponents(l-s,p-h,v-m,w-_).normalize(),r[1].setComponents(l+s,p+h,v+m,w+_).normalize(),r[2].setComponents(l+o,p+u,v+g,w+y).normalize(),r[3].setComponents(l-o,p-u,v-g,w-y).normalize(),n)r[4].setComponents(c,d,f,S).normalize(),r[5].setComponents(l-c,p-d,v-f,w-S).normalize();else if(r[4].setComponents(l-c,p-d,v-f,w-S).normalize(),t===Ei)r[5].setComponents(l+c,p+d,v+f,w+S).normalize();else{if(t!==Oa)throw new Error("THREE.Frustum.setFromProjectionMatrix(): Invalid coordinate system: "+t);r[5].setComponents(c,d,f,S).normalize()}return this}intersectsObject(e){if(e.boundingSphere!==void 0)e.boundingSphere===null&&e.computeBoundingSphere(),ur.copy(e.boundingSphere).applyMatrix4(e.matrixWorld);else{let t=e.geometry;t.boundingSphere===null&&t.computeBoundingSphere(),ur.copy(t.boundingSphere).applyMatrix4(e.matrixWorld)}return this.intersectsSphere(ur)}intersectsSprite(e){ur.center.set(0,0,0);let t=Rp.distanceTo(e.center);return ur.radius=.7071067811865476+t,ur.applyMatrix4(e.matrixWorld),this.intersectsSphere(ur)}intersectsSphere(e){let t=this.planes,n=e.center,r=-e.radius;for(let a=0;a<6;a++)if(t[a].distanceToPoint(n)<r)return!1;return!0}intersectsBox(e){let t=this.planes;for(let n=0;n<6;n++){let r=t[n];if(Os.x=r.normal.x>0?e.max.x:e.min.x,Os.y=r.normal.y>0?e.max.y:e.min.y,Os.z=r.normal.z>0?e.max.z:e.min.z,r.distanceToPoint(Os)<0)return!1}return!0}containsPoint(e){let t=this.planes;for(let n=0;n<6;n++)if(t[n].distanceToPoint(e)<0)return!1;return!0}clone(){return new this.constructor().copy(this)}},Qn=new qe,ei=new qi,no=class i{constructor(){this.coordinateSystem=Ei}intersectsObject(e,t){if(!t.isArrayCamera||t.cameras.length===0)return!1;for(let n=0;n<t.cameras.length;n++){let r=t.cameras[n];if(Qn.multiplyMatrices(r.projectionMatrix,r.matrixWorldInverse),ei.setFromProjectionMatrix(Qn,r.coordinateSystem,r.reversedDepth),ei.intersectsObject(e))return!0}return!1}intersectsSprite(e,t){if(!t||!t.cameras||t.cameras.length===0)return!1;for(let n=0;n<t.cameras.length;n++){let r=t.cameras[n];if(Qn.multiplyMatrices(r.projectionMatrix,r.matrixWorldInverse),ei.setFromProjectionMatrix(Qn,r.coordinateSystem,r.reversedDepth),ei.intersectsSprite(e))return!0}return!1}intersectsSphere(e,t){if(!t||!t.cameras||t.cameras.length===0)return!1;for(let n=0;n<t.cameras.length;n++){let r=t.cameras[n];if(Qn.multiplyMatrices(r.projectionMatrix,r.matrixWorldInverse),ei.setFromProjectionMatrix(Qn,r.coordinateSystem,r.reversedDepth),ei.intersectsSphere(e))return!0}return!1}intersectsBox(e,t){if(!t||!t.cameras||t.cameras.length===0)return!1;for(let n=0;n<t.cameras.length;n++){let r=t.cameras[n];if(Qn.multiplyMatrices(r.projectionMatrix,r.matrixWorldInverse),ei.setFromProjectionMatrix(Qn,r.coordinateSystem,r.reversedDepth),ei.intersectsBox(e))return!0}return!1}containsPoint(e,t){if(!t||!t.cameras||t.cameras.length===0)return!1;for(let n=0;n<t.cameras.length;n++){let r=t.cameras[n];if(Qn.multiplyMatrices(r.projectionMatrix,r.matrixWorldInverse),ei.setFromProjectionMatrix(Qn,r.coordinateSystem,r.reversedDepth),ei.containsPoint(e))return!0}return!1}clone(){return new i}};var Ql=class{constructor(){this.index=0,this.pool=[],this.list=[]}push(e,t,n,r){let a=this.pool,s=this.list;this.index>=a.length&&a.push({start:-1,count:-1,z:-1,index:-1});let o=a[this.index];s.push(o),this.index++,o.start=e,o.count=t,o.z=n,o.index=r}reset(){this.list.length=0,this.index=0}},_0=new qe,y0=new Ve(1,1,1),x0=new qi,M0=new no,S0=new Nn,b0=new Fn,T0=new E,E0=new E,w0=new E,A0=new Ql,R0=new Le;var C0=new E,P0=new E,I0=new qe,L0=new fr,D0=new Fn,U0=new E,N0=new E;var F0=new E,O0=new E;var io=class extends Ai{constructor(e){super(),this.isPointsMaterial=!0,this.type="PointsMaterial",this.color=new Ve(16777215),this.map=null,this.alphaMap=null,this.size=1,this.sizeAttenuation=!0,this.fog=!0,this.setValues(e)}copy(e){return super.copy(e),this.color.copy(e.color),this.map=e.map,this.alphaMap=e.alphaMap,this.size=e.size,this.sizeAttenuation=e.sizeAttenuation,this.fog=e.fog,this}},tu=new qe,ec=new fr,Bs=new Fn,ks=new E,Yi=class extends Kt{constructor(e=new mt,t=new io){super(),this.isPoints=!0,this.type="Points",this.geometry=e,this.material=t,this.morphTargetDictionary=void 0,this.morphTargetInfluences=void 0,this.updateMorphTargets()}copy(e,t){return super.copy(e,t),this.material=Array.isArray(e.material)?e.material.slice():e.material,this.geometry=e.geometry,this}raycast(e,t){let n=this.geometry,r=this.matrixWorld,a=e.params.Points.threshold,s=n.drawRange;if(n.boundingSphere===null&&n.computeBoundingSphere(),Bs.copy(n.boundingSphere),Bs.applyMatrix4(r),Bs.radius+=a,e.ray.intersectsSphere(Bs)===!1)return;tu.copy(r).invert(),ec.copy(e.ray).applyMatrix4(tu);let o=a/((this.scale.x+this.scale.y+this.scale.z)/3),c=o*o,l=n.index,h=n.attributes.position;if(l!==null)for(let u=Math.max(0,s.start),d=Math.min(l.count,s.start+s.count);u<d;u++){let p=l.getX(u);ks.fromBufferAttribute(h,p),nu(ks,p,c,r,e,t,this)}else for(let u=Math.max(0,s.start),d=Math.min(h.count,s.start+s.count);u<d;u++)ks.fromBufferAttribute(h,u),nu(ks,u,c,r,e,t,this)}updateMorphTargets(){let e=this.geometry.morphAttributes,t=Object.keys(e);if(t.length>0){let n=e[t[0]];if(n!==void 0){this.morphTargetInfluences=[],this.morphTargetDictionary={};for(let r=0,a=n.length;r<a;r++){let s=n[r].name||String(r);this.morphTargetInfluences.push(0),this.morphTargetDictionary[s]=r}}}}};function nu(i,e,t,n,r,a,s){let o=ec.distanceSqToPoint(i);if(o<t){let c=new E;ec.closestPointToPoint(i,c),c.applyMatrix4(n);let l=r.ray.origin.distanceTo(c);if(l<r.near||l>r.far)return;a.push({distance:l,distanceToRay:Math.sqrt(o),point:c,index:e,face:null,faceIndex:null,barycoord:null,object:s})}}var Ri=class extends fn{constructor(e,t,n,r,a,s,o,c,l){super(e,t,n,r,a,s,o,c,l),this.isCanvasTexture=!0,this.needsUpdate=!0}},Xa=class extends fn{constructor(e,t,n=1014,r,a,s,o=1003,c=1003,l,h=1026,u=1){if(h!==cs&&h!==1027)throw new Error("DepthTexture format must be either THREE.DepthFormat or THREE.DepthStencilFormat");super({width:e,height:t,depth:u},r,a,s,o,c,h,n,l),this.isDepthTexture=!0,this.flipY=!1,this.generateMipmaps=!1,this.compareFunction=null}copy(e){return super.copy(e),this.source=new ta(Object.assign({},e.image)),this.compareFunction=e.compareFunction,this}toJSON(e){let t=super.toJSON(e);return this.compareFunction!==null&&(t.compareFunction=this.compareFunction),t}},ja=class extends fn{constructor(e=null){super(),this.sourceTexture=e,this.isExternalTexture=!0}copy(e){return super.copy(e),this.sourceTexture=e.sourceTexture,this}},ro=class i extends mt{constructor(e=1,t=1,n=4,r=8,a=1){super(),this.type="CapsuleGeometry",this.parameters={radius:e,height:t,capSegments:n,radialSegments:r,heightSegments:a},t=Math.max(0,t),n=Math.max(1,Math.floor(n)),r=Math.max(3,Math.floor(r)),a=Math.max(1,Math.floor(a));let s=[],o=[],c=[],l=[],h=t/2,u=Math.PI/2*e,d=t,p=2*u+d,m=2*n+a,g=r+1,f=new E,v=new E;for(let _=0;_<=m;_++){let y=0,S=0,w=0,R=0;if(_<=n){let D=_/n,J=D*Math.PI/2;S=-h-e*Math.cos(J),w=e*Math.sin(J),R=-e*Math.cos(J),y=D*u}else if(_<=n+a){let D=(_-n)/a;S=D*t-h,w=e,R=0,y=u+D*d}else{let D=(_-n-a)/n,J=D*Math.PI/2;S=h+e*Math.sin(J),w=e*Math.cos(J),R=e*Math.sin(J),y=u+d+D*u}let B=Math.max(0,Math.min(1,y/p)),G=0;_===0?G=.5/r:_===m&&(G=-.5/r);for(let D=0;D<=r;D++){let J=D/r,K=J*Math.PI*2,V=Math.sin(K),se=Math.cos(K);v.x=-w*se,v.y=S,v.z=w*V,o.push(v.x,v.y,v.z),f.set(-w*se,R,w*V),f.normalize(),c.push(f.x,f.y,f.z),l.push(J+G,B)}if(_>0){let D=(_-1)*g;for(let J=0;J<r;J++){let K=D+J,V=D+J+1,se=_*g+J,X=_*g+J+1;s.push(K,V,se),s.push(V,X,se)}}}this.setIndex(s),this.setAttribute("position",new Ye(o,3)),this.setAttribute("normal",new Ye(c,3)),this.setAttribute("uv",new Ye(l,2))}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}static fromJSON(e){return new i(e.radius,e.height,e.capSegments,e.radialSegments,e.heightSegments)}},Ci=class i extends mt{constructor(e=1,t=32,n=0,r=2*Math.PI){super(),this.type="CircleGeometry",this.parameters={radius:e,segments:t,thetaStart:n,thetaLength:r},t=Math.max(3,t);let a=[],s=[],o=[],c=[],l=new E,h=new pe;s.push(0,0,0),o.push(0,0,1),c.push(.5,.5);for(let u=0,d=3;u<=t;u++,d+=3){let p=n+u/t*r;l.x=e*Math.cos(p),l.y=e*Math.sin(p),s.push(l.x,l.y,l.z),o.push(0,0,1),h.x=(s[d]/e+1)/2,h.y=(s[d+1]/e+1)/2,c.push(h.x,h.y)}for(let u=1;u<=t;u++)a.push(u,u+1,0);this.setIndex(a),this.setAttribute("position",new Ye(s,3)),this.setAttribute("normal",new Ye(o,3)),this.setAttribute("uv",new Ye(c,2))}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}static fromJSON(e){return new i(e.radius,e.segments,e.thetaStart,e.thetaLength)}},gt=class i extends mt{constructor(e=1,t=1,n=1,r=32,a=1,s=!1,o=0,c=2*Math.PI){super(),this.type="CylinderGeometry",this.parameters={radiusTop:e,radiusBottom:t,height:n,radialSegments:r,heightSegments:a,openEnded:s,thetaStart:o,thetaLength:c};let l=this;r=Math.floor(r),a=Math.floor(a);let h=[],u=[],d=[],p=[],m=0,g=[],f=n/2,v=0;function _(y){let S=m,w=new pe,R=new E,B=0,G=y===!0?e:t,D=y===!0?1:-1;for(let K=1;K<=r;K++)u.push(0,f*D,0),d.push(0,D,0),p.push(.5,.5),m++;let J=m;for(let K=0;K<=r;K++){let V=K/r*c+o,se=Math.cos(V),X=Math.sin(V);R.x=G*X,R.y=f*D,R.z=G*se,u.push(R.x,R.y,R.z),d.push(0,D,0),w.x=.5*se+.5,w.y=.5*X*D+.5,p.push(w.x,w.y),m++}for(let K=0;K<r;K++){let V=S+K,se=J+K;y===!0?h.push(se,se+1,V):h.push(se+1,se,V),B+=3}l.addGroup(v,B,y===!0?1:2),v+=B}(function(){let y=new E,S=new E,w=0,R=(t-e)/n;for(let B=0;B<=a;B++){let G=[],D=B/a,J=D*(t-e)+e;for(let K=0;K<=r;K++){let V=K/r,se=V*c+o,X=Math.sin(se),ee=Math.cos(se);S.x=J*X,S.y=-D*n+f,S.z=J*ee,u.push(S.x,S.y,S.z),y.set(X,R,ee).normalize(),d.push(y.x,y.y,y.z),p.push(V,1-D),G.push(m++)}g.push(G)}for(let B=0;B<r;B++)for(let G=0;G<a;G++){let D=g[G][B],J=g[G+1][B],K=g[G+1][B+1],V=g[G][B+1];(e>0||G!==0)&&(h.push(D,J,V),w+=3),(t>0||G!==a-1)&&(h.push(J,K,V),w+=3)}l.addGroup(v,w,0),v+=w})(),s===!1&&(e>0&&_(!0),t>0&&_(!1)),this.setIndex(h),this.setAttribute("position",new Ye(u,3)),this.setAttribute("normal",new Ye(d,3)),this.setAttribute("uv",new Ye(p,2))}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}static fromJSON(e){return new i(e.radiusTop,e.radiusBottom,e.height,e.radialSegments,e.heightSegments,e.openEnded,e.thetaStart,e.thetaLength)}},ao=class i extends gt{constructor(e=1,t=1,n=32,r=1,a=!1,s=0,o=2*Math.PI){super(0,e,t,n,r,a,s,o),this.type="ConeGeometry",this.parameters={radius:e,height:t,radialSegments:n,heightSegments:r,openEnded:a,thetaStart:s,thetaLength:o}}static fromJSON(e){return new i(e.radius,e.height,e.radialSegments,e.heightSegments,e.openEnded,e.thetaStart,e.thetaLength)}},Zi=class i extends mt{constructor(e=[],t=[],n=1,r=0){super(),this.type="PolyhedronGeometry",this.parameters={vertices:e,indices:t,radius:n,detail:r};let a=[],s=[];function o(p,m,g,f){let v=f+1,_=[];for(let y=0;y<=v;y++){_[y]=[];let S=p.clone().lerp(g,y/v),w=m.clone().lerp(g,y/v),R=v-y;for(let B=0;B<=R;B++)_[y][B]=B===0&&y===v?S:S.clone().lerp(w,B/R)}for(let y=0;y<v;y++)for(let S=0;S<2*(v-y)-1;S++){let w=Math.floor(S/2);S%2==0?(c(_[y][w+1]),c(_[y+1][w]),c(_[y][w])):(c(_[y][w+1]),c(_[y+1][w+1]),c(_[y+1][w]))}}function c(p){a.push(p.x,p.y,p.z)}function l(p,m){let g=3*p;m.x=e[g+0],m.y=e[g+1],m.z=e[g+2]}function h(p,m,g,f){f<0&&p.x===1&&(s[m]=p.x-1),g.x===0&&g.z===0&&(s[m]=f/2/Math.PI+.5)}function u(p){return Math.atan2(p.z,-p.x)}function d(p){return Math.atan2(-p.y,Math.sqrt(p.x*p.x+p.z*p.z))}(function(p){let m=new E,g=new E,f=new E;for(let v=0;v<t.length;v+=3)l(t[v+0],m),l(t[v+1],g),l(t[v+2],f),o(m,g,f,p)})(r),(function(p){let m=new E;for(let g=0;g<a.length;g+=3)m.x=a[g+0],m.y=a[g+1],m.z=a[g+2],m.normalize().multiplyScalar(p),a[g+0]=m.x,a[g+1]=m.y,a[g+2]=m.z})(n),(function(){let p=new E;for(let m=0;m<a.length;m+=3){p.x=a[m+0],p.y=a[m+1],p.z=a[m+2];let g=u(p)/2/Math.PI+.5,f=d(p)/Math.PI+.5;s.push(g,1-f)}(function(){let m=new E,g=new E,f=new E,v=new E,_=new pe,y=new pe,S=new pe;for(let w=0,R=0;w<a.length;w+=9,R+=6){m.set(a[w+0],a[w+1],a[w+2]),g.set(a[w+3],a[w+4],a[w+5]),f.set(a[w+6],a[w+7],a[w+8]),_.set(s[R+0],s[R+1]),y.set(s[R+2],s[R+3]),S.set(s[R+4],s[R+5]),v.copy(m).add(g).add(f).divideScalar(3);let B=u(v);h(_,R+0,m,B),h(y,R+2,g,B),h(S,R+4,f,B)}})(),(function(){for(let m=0;m<s.length;m+=6){let g=s[m+0],f=s[m+2],v=s[m+4],_=Math.max(g,f,v),y=Math.min(g,f,v);_>.9&&y<.1&&(g<.2&&(s[m+0]+=1),f<.2&&(s[m+2]+=1),v<.2&&(s[m+4]+=1))}})()})(),this.setAttribute("position",new Ye(a,3)),this.setAttribute("normal",new Ye(a.slice(),3)),this.setAttribute("uv",new Ye(s,2)),r===0?this.computeVertexNormals():this.normalizeNormals()}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}static fromJSON(e){return new i(e.vertices,e.indices,e.radius,e.details)}},so=class i extends Zi{constructor(e=1,t=0){let n=(1+Math.sqrt(5))/2,r=1/n;super([-1,-1,-1,-1,-1,1,-1,1,-1,-1,1,1,1,-1,-1,1,-1,1,1,1,-1,1,1,1,0,-r,-n,0,-r,n,0,r,-n,0,r,n,-r,-n,0,-r,n,0,r,-n,0,r,n,0,-n,0,-r,n,0,-r,-n,0,r,n,0,r],[3,11,7,3,7,15,3,15,13,7,19,17,7,17,6,7,6,15,17,4,8,17,8,10,17,10,6,8,0,16,8,16,2,8,2,10,0,12,1,0,1,18,0,18,16,6,10,2,6,2,13,6,13,15,2,16,18,2,18,3,2,3,13,18,1,9,18,9,11,18,11,3,4,14,12,4,12,0,4,0,8,11,9,5,11,5,19,11,19,7,19,5,14,19,14,4,19,4,17,1,12,14,1,14,5,1,5,9],e,t),this.type="DodecahedronGeometry",this.parameters={radius:e,detail:t}}static fromJSON(e){return new i(e.radius,e.detail)}},zs=new E,Hs=new E,Gl=new E,Gs=new bi,oo=class extends mt{constructor(e=null,t=1){if(super(),this.type="EdgesGeometry",this.parameters={geometry:e,thresholdAngle:t},e!==null){let r=Math.pow(10,4),a=Math.cos(Jr*t),s=e.getIndex(),o=e.getAttribute("position"),c=s?s.count:o.count,l=[0,0,0],h=["a","b","c"],u=new Array(3),d={},p=[];for(let m=0;m<c;m+=3){s?(l[0]=s.getX(m),l[1]=s.getX(m+1),l[2]=s.getX(m+2)):(l[0]=m,l[1]=m+1,l[2]=m+2);let{a:g,b:f,c:v}=Gs;if(g.fromBufferAttribute(o,l[0]),f.fromBufferAttribute(o,l[1]),v.fromBufferAttribute(o,l[2]),Gs.getNormal(Gl),u[0]=`${Math.round(g.x*r)},${Math.round(g.y*r)},${Math.round(g.z*r)}`,u[1]=`${Math.round(f.x*r)},${Math.round(f.y*r)},${Math.round(f.z*r)}`,u[2]=`${Math.round(v.x*r)},${Math.round(v.y*r)},${Math.round(v.z*r)}`,u[0]!==u[1]&&u[1]!==u[2]&&u[2]!==u[0])for(let _=0;_<3;_++){let y=(_+1)%3,S=u[_],w=u[y],R=Gs[h[_]],B=Gs[h[y]],G=`${S}_${w}`,D=`${w}_${S}`;D in d&&d[D]?(Gl.dot(d[D].normal)<=a&&(p.push(R.x,R.y,R.z),p.push(B.x,B.y,B.z)),d[D]=null):G in d||(d[G]={index0:l[_],index1:l[y],normal:Gl.clone()})}}for(let m in d)if(d[m]){let{index0:g,index1:f}=d[m];zs.fromBufferAttribute(o,g),Hs.fromBufferAttribute(o,f),p.push(zs.x,zs.y,zs.z),p.push(Hs.x,Hs.y,Hs.z)}this.setAttribute("position",new Ye(p,3))}}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}},wn=class{constructor(){this.type="Curve",this.arcLengthDivisions=200,this.needsUpdate=!1,this.cacheArcLengths=null}getPoint(){console.warn("THREE.Curve: .getPoint() not implemented.")}getPointAt(e,t){let n=this.getUtoTmapping(e);return this.getPoint(n,t)}getPoints(e=5){let t=[];for(let n=0;n<=e;n++)t.push(this.getPoint(n/e));return t}getSpacedPoints(e=5){let t=[];for(let n=0;n<=e;n++)t.push(this.getPointAt(n/e));return t}getLength(){let e=this.getLengths();return e[e.length-1]}getLengths(e=this.arcLengthDivisions){if(this.cacheArcLengths&&this.cacheArcLengths.length===e+1&&!this.needsUpdate)return this.cacheArcLengths;this.needsUpdate=!1;let t=[],n,r=this.getPoint(0),a=0;t.push(0);for(let s=1;s<=e;s++)n=this.getPoint(s/e),a+=n.distanceTo(r),t.push(a),r=n;return this.cacheArcLengths=t,t}updateArcLengths(){this.needsUpdate=!0,this.getLengths()}getUtoTmapping(e,t=null){let n=this.getLengths(),r=0,a=n.length,s;s=t||e*n[a-1];let o,c=0,l=a-1;for(;c<=l;)if(r=Math.floor(c+(l-c)/2),o=n[r]-s,o<0)c=r+1;else{if(!(o>0)){l=r;break}l=r-1}if(r=l,n[r]===s)return r/(a-1);let h=n[r];return(r+(s-h)/(n[r+1]-h))/(a-1)}getTangent(e,t){let r=e-1e-4,a=e+1e-4;r<0&&(r=0),a>1&&(a=1);let s=this.getPoint(r),o=this.getPoint(a),c=t||(s.isVector2?new pe:new E);return c.copy(o).sub(s).normalize(),c}getTangentAt(e,t){let n=this.getUtoTmapping(e);return this.getTangent(n,t)}computeFrenetFrames(e,t=!1){let n=new E,r=[],a=[],s=[],o=new E,c=new qe;for(let p=0;p<=e;p++){let m=p/e;r[p]=this.getTangentAt(m,new E)}a[0]=new E,s[0]=new E;let l=Number.MAX_VALUE,h=Math.abs(r[0].x),u=Math.abs(r[0].y),d=Math.abs(r[0].z);h<=l&&(l=h,n.set(1,0,0)),u<=l&&(l=u,n.set(0,1,0)),d<=l&&n.set(0,0,1),o.crossVectors(r[0],n).normalize(),a[0].crossVectors(r[0],o),s[0].crossVectors(r[0],a[0]);for(let p=1;p<=e;p++){if(a[p]=a[p-1].clone(),s[p]=s[p-1].clone(),o.crossVectors(r[p-1],r[p]),o.length()>Number.EPSILON){o.normalize();let m=Math.acos(at(r[p-1].dot(r[p]),-1,1));a[p].applyMatrix4(c.makeRotationAxis(o,m))}s[p].crossVectors(r[p],a[p])}if(t===!0){let p=Math.acos(at(a[0].dot(a[e]),-1,1));p/=e,r[0].dot(o.crossVectors(a[0],a[e]))>0&&(p=-p);for(let m=1;m<=e;m++)a[m].applyMatrix4(c.makeRotationAxis(r[m],p*m)),s[m].crossVectors(r[m],a[m])}return{tangents:r,normals:a,binormals:s}}clone(){return new this.constructor().copy(this)}copy(e){return this.arcLengthDivisions=e.arcLengthDivisions,this}toJSON(){let e={metadata:{version:4.7,type:"Curve",generator:"Curve.toJSON"}};return e.arcLengthDivisions=this.arcLengthDivisions,e.type=this.type,e}fromJSON(e){return this.arcLengthDivisions=e.arcLengthDivisions,this}},ra=class extends wn{constructor(e=0,t=0,n=1,r=1,a=0,s=2*Math.PI,o=!1,c=0){super(),this.isEllipseCurve=!0,this.type="EllipseCurve",this.aX=e,this.aY=t,this.xRadius=n,this.yRadius=r,this.aStartAngle=a,this.aEndAngle=s,this.aClockwise=o,this.aRotation=c}getPoint(e,t=new pe){let n=t,r=2*Math.PI,a=this.aEndAngle-this.aStartAngle,s=Math.abs(a)<Number.EPSILON;for(;a<0;)a+=r;for(;a>r;)a-=r;a<Number.EPSILON&&(a=s?0:r),this.aClockwise!==!0||s||(a===r?a=-r:a-=r);let o=this.aStartAngle+e*a,c=this.aX+this.xRadius*Math.cos(o),l=this.aY+this.yRadius*Math.sin(o);if(this.aRotation!==0){let h=Math.cos(this.aRotation),u=Math.sin(this.aRotation),d=c-this.aX,p=l-this.aY;c=d*h-p*u+this.aX,l=d*u+p*h+this.aY}return n.set(c,l)}copy(e){return super.copy(e),this.aX=e.aX,this.aY=e.aY,this.xRadius=e.xRadius,this.yRadius=e.yRadius,this.aStartAngle=e.aStartAngle,this.aEndAngle=e.aEndAngle,this.aClockwise=e.aClockwise,this.aRotation=e.aRotation,this}toJSON(){let e=super.toJSON();return e.aX=this.aX,e.aY=this.aY,e.xRadius=this.xRadius,e.yRadius=this.yRadius,e.aStartAngle=this.aStartAngle,e.aEndAngle=this.aEndAngle,e.aClockwise=this.aClockwise,e.aRotation=this.aRotation,e}fromJSON(e){return super.fromJSON(e),this.aX=e.aX,this.aY=e.aY,this.xRadius=e.xRadius,this.yRadius=e.yRadius,this.aStartAngle=e.aStartAngle,this.aEndAngle=e.aEndAngle,this.aClockwise=e.aClockwise,this.aRotation=e.aRotation,this}},lo=class extends ra{constructor(e,t,n,r,a,s){super(e,t,n,n,r,a,s),this.isArcCurve=!0,this.type="ArcCurve"}};function Jc(){let i=0,e=0,t=0,n=0;function r(a,s,o,c){i=a,e=o,t=-3*a+3*s-2*o-c,n=2*a-2*s+o+c}return{initCatmullRom:function(a,s,o,c,l){r(s,o,l*(o-a),l*(c-s))},initNonuniformCatmullRom:function(a,s,o,c,l,h,u){let d=(s-a)/l-(o-a)/(l+h)+(o-s)/h,p=(o-s)/h-(c-s)/(h+u)+(c-o)/u;d*=h,p*=h,r(s,o,d,p)},calc:function(a){let s=a*a;return i+e*a+t*s+n*(s*a)}}}var Vs=new E,Vl=new Jc,Wl=new Jc,Xl=new Jc,co=class extends wn{constructor(e=[],t=!1,n="centripetal",r=.5){super(),this.isCatmullRomCurve3=!0,this.type="CatmullRomCurve3",this.points=e,this.closed=t,this.curveType=n,this.tension=r}getPoint(e,t=new E){let n=t,r=this.points,a=r.length,s=(a-(this.closed?0:1))*e,o,c,l=Math.floor(s),h=s-l;this.closed?l+=l>0?0:(Math.floor(Math.abs(l)/a)+1)*a:h===0&&l===a-1&&(l=a-2,h=1),this.closed||l>0?o=r[(l-1)%a]:(Vs.subVectors(r[0],r[1]).add(r[0]),o=Vs);let u=r[l%a],d=r[(l+1)%a];if(this.closed||l+2<a?c=r[(l+2)%a]:(Vs.subVectors(r[a-1],r[a-2]).add(r[a-1]),c=Vs),this.curveType==="centripetal"||this.curveType==="chordal"){let p=this.curveType==="chordal"?.5:.25,m=Math.pow(o.distanceToSquared(u),p),g=Math.pow(u.distanceToSquared(d),p),f=Math.pow(d.distanceToSquared(c),p);g<1e-4&&(g=1),m<1e-4&&(m=g),f<1e-4&&(f=g),Vl.initNonuniformCatmullRom(o.x,u.x,d.x,c.x,m,g,f),Wl.initNonuniformCatmullRom(o.y,u.y,d.y,c.y,m,g,f),Xl.initNonuniformCatmullRom(o.z,u.z,d.z,c.z,m,g,f)}else this.curveType==="catmullrom"&&(Vl.initCatmullRom(o.x,u.x,d.x,c.x,this.tension),Wl.initCatmullRom(o.y,u.y,d.y,c.y,this.tension),Xl.initCatmullRom(o.z,u.z,d.z,c.z,this.tension));return n.set(Vl.calc(h),Wl.calc(h),Xl.calc(h)),n}copy(e){super.copy(e),this.points=[];for(let t=0,n=e.points.length;t<n;t++){let r=e.points[t];this.points.push(r.clone())}return this.closed=e.closed,this.curveType=e.curveType,this.tension=e.tension,this}toJSON(){let e=super.toJSON();e.points=[];for(let t=0,n=this.points.length;t<n;t++){let r=this.points[t];e.points.push(r.toArray())}return e.closed=this.closed,e.curveType=this.curveType,e.tension=this.tension,e}fromJSON(e){super.fromJSON(e),this.points=[];for(let t=0,n=e.points.length;t<n;t++){let r=e.points[t];this.points.push(new E().fromArray(r))}return this.closed=e.closed,this.curveType=e.curveType,this.tension=e.tension,this}};function iu(i,e,t,n,r){let a=.5*(n-e),s=.5*(r-t),o=i*i;return(2*t-2*n+a+s)*(i*o)+(-3*t+3*n-2*a-s)*o+a*i+t}function Da(i,e,t,n){return(function(r,a){let s=1-r;return s*s*a})(i,e)+(function(r,a){return 2*(1-r)*r*a})(i,t)+(function(r,a){return r*r*a})(i,n)}function Ua(i,e,t,n,r){return(function(a,s){let o=1-a;return o*o*o*s})(i,e)+(function(a,s){let o=1-a;return 3*o*o*a*s})(i,t)+(function(a,s){return 3*(1-a)*a*a*s})(i,n)+(function(a,s){return a*a*a*s})(i,r)}var qa=class extends wn{constructor(e=new pe,t=new pe,n=new pe,r=new pe){super(),this.isCubicBezierCurve=!0,this.type="CubicBezierCurve",this.v0=e,this.v1=t,this.v2=n,this.v3=r}getPoint(e,t=new pe){let n=t,r=this.v0,a=this.v1,s=this.v2,o=this.v3;return n.set(Ua(e,r.x,a.x,s.x,o.x),Ua(e,r.y,a.y,s.y,o.y)),n}copy(e){return super.copy(e),this.v0.copy(e.v0),this.v1.copy(e.v1),this.v2.copy(e.v2),this.v3.copy(e.v3),this}toJSON(){let e=super.toJSON();return e.v0=this.v0.toArray(),e.v1=this.v1.toArray(),e.v2=this.v2.toArray(),e.v3=this.v3.toArray(),e}fromJSON(e){return super.fromJSON(e),this.v0.fromArray(e.v0),this.v1.fromArray(e.v1),this.v2.fromArray(e.v2),this.v3.fromArray(e.v3),this}},ho=class extends wn{constructor(e=new E,t=new E,n=new E,r=new E){super(),this.isCubicBezierCurve3=!0,this.type="CubicBezierCurve3",this.v0=e,this.v1=t,this.v2=n,this.v3=r}getPoint(e,t=new E){let n=t,r=this.v0,a=this.v1,s=this.v2,o=this.v3;return n.set(Ua(e,r.x,a.x,s.x,o.x),Ua(e,r.y,a.y,s.y,o.y),Ua(e,r.z,a.z,s.z,o.z)),n}copy(e){return super.copy(e),this.v0.copy(e.v0),this.v1.copy(e.v1),this.v2.copy(e.v2),this.v3.copy(e.v3),this}toJSON(){let e=super.toJSON();return e.v0=this.v0.toArray(),e.v1=this.v1.toArray(),e.v2=this.v2.toArray(),e.v3=this.v3.toArray(),e}fromJSON(e){return super.fromJSON(e),this.v0.fromArray(e.v0),this.v1.fromArray(e.v1),this.v2.fromArray(e.v2),this.v3.fromArray(e.v3),this}},Ya=class extends wn{constructor(e=new pe,t=new pe){super(),this.isLineCurve=!0,this.type="LineCurve",this.v1=e,this.v2=t}getPoint(e,t=new pe){let n=t;return e===1?n.copy(this.v2):(n.copy(this.v2).sub(this.v1),n.multiplyScalar(e).add(this.v1)),n}getPointAt(e,t){return this.getPoint(e,t)}getTangent(e,t=new pe){return t.subVectors(this.v2,this.v1).normalize()}getTangentAt(e,t){return this.getTangent(e,t)}copy(e){return super.copy(e),this.v1.copy(e.v1),this.v2.copy(e.v2),this}toJSON(){let e=super.toJSON();return e.v1=this.v1.toArray(),e.v2=this.v2.toArray(),e}fromJSON(e){return super.fromJSON(e),this.v1.fromArray(e.v1),this.v2.fromArray(e.v2),this}},uo=class extends wn{constructor(e=new E,t=new E){super(),this.isLineCurve3=!0,this.type="LineCurve3",this.v1=e,this.v2=t}getPoint(e,t=new E){let n=t;return e===1?n.copy(this.v2):(n.copy(this.v2).sub(this.v1),n.multiplyScalar(e).add(this.v1)),n}getPointAt(e,t){return this.getPoint(e,t)}getTangent(e,t=new E){return t.subVectors(this.v2,this.v1).normalize()}getTangentAt(e,t){return this.getTangent(e,t)}copy(e){return super.copy(e),this.v1.copy(e.v1),this.v2.copy(e.v2),this}toJSON(){let e=super.toJSON();return e.v1=this.v1.toArray(),e.v2=this.v2.toArray(),e}fromJSON(e){return super.fromJSON(e),this.v1.fromArray(e.v1),this.v2.fromArray(e.v2),this}},Za=class extends wn{constructor(e=new pe,t=new pe,n=new pe){super(),this.isQuadraticBezierCurve=!0,this.type="QuadraticBezierCurve",this.v0=e,this.v1=t,this.v2=n}getPoint(e,t=new pe){let n=t,r=this.v0,a=this.v1,s=this.v2;return n.set(Da(e,r.x,a.x,s.x),Da(e,r.y,a.y,s.y)),n}copy(e){return super.copy(e),this.v0.copy(e.v0),this.v1.copy(e.v1),this.v2.copy(e.v2),this}toJSON(){let e=super.toJSON();return e.v0=this.v0.toArray(),e.v1=this.v1.toArray(),e.v2=this.v2.toArray(),e}fromJSON(e){return super.fromJSON(e),this.v0.fromArray(e.v0),this.v1.fromArray(e.v1),this.v2.fromArray(e.v2),this}},Ja=class extends wn{constructor(e=new E,t=new E,n=new E){super(),this.isQuadraticBezierCurve3=!0,this.type="QuadraticBezierCurve3",this.v0=e,this.v1=t,this.v2=n}getPoint(e,t=new E){let n=t,r=this.v0,a=this.v1,s=this.v2;return n.set(Da(e,r.x,a.x,s.x),Da(e,r.y,a.y,s.y),Da(e,r.z,a.z,s.z)),n}copy(e){return super.copy(e),this.v0.copy(e.v0),this.v1.copy(e.v1),this.v2.copy(e.v2),this}toJSON(){let e=super.toJSON();return e.v0=this.v0.toArray(),e.v1=this.v1.toArray(),e.v2=this.v2.toArray(),e}fromJSON(e){return super.fromJSON(e),this.v0.fromArray(e.v0),this.v1.fromArray(e.v1),this.v2.fromArray(e.v2),this}},Ka=class extends wn{constructor(e=[]){super(),this.isSplineCurve=!0,this.type="SplineCurve",this.points=e}getPoint(e,t=new pe){let n=t,r=this.points,a=(r.length-1)*e,s=Math.floor(a),o=a-s,c=r[s===0?s:s-1],l=r[s],h=r[s>r.length-2?r.length-1:s+1],u=r[s>r.length-3?r.length-1:s+2];return n.set(iu(o,c.x,l.x,h.x,u.x),iu(o,c.y,l.y,h.y,u.y)),n}copy(e){super.copy(e),this.points=[];for(let t=0,n=e.points.length;t<n;t++){let r=e.points[t];this.points.push(r.clone())}return this}toJSON(){let e=super.toJSON();e.points=[];for(let t=0,n=this.points.length;t<n;t++){let r=this.points[t];e.points.push(r.toArray())}return e}fromJSON(e){super.fromJSON(e),this.points=[];for(let t=0,n=e.points.length;t<n;t++){let r=e.points[t];this.points.push(new pe().fromArray(r))}return this}},po=Object.freeze({__proto__:null,ArcCurve:lo,CatmullRomCurve3:co,CubicBezierCurve:qa,CubicBezierCurve3:ho,EllipseCurve:ra,LineCurve:Ya,LineCurve3:uo,QuadraticBezierCurve:Za,QuadraticBezierCurve3:Ja,SplineCurve:Ka}),fo=class extends wn{constructor(){super(),this.type="CurvePath",this.curves=[],this.autoClose=!1}add(e){this.curves.push(e)}closePath(){let e=this.curves[0].getPoint(0),t=this.curves[this.curves.length-1].getPoint(1);if(!e.equals(t)){let n=e.isVector2===!0?"LineCurve":"LineCurve3";this.curves.push(new po[n](t,e))}return this}getPoint(e,t){let n=e*this.getLength(),r=this.getCurveLengths(),a=0;for(;a<r.length;){if(r[a]>=n){let s=r[a]-n,o=this.curves[a],c=o.getLength(),l=c===0?0:1-s/c;return o.getPointAt(l,t)}a++}return null}getLength(){let e=this.getCurveLengths();return e[e.length-1]}updateArcLengths(){this.needsUpdate=!0,this.cacheLengths=null,this.getCurveLengths()}getCurveLengths(){if(this.cacheLengths&&this.cacheLengths.length===this.curves.length)return this.cacheLengths;let e=[],t=0;for(let n=0,r=this.curves.length;n<r;n++)t+=this.curves[n].getLength(),e.push(t);return this.cacheLengths=e,e}getSpacedPoints(e=40){let t=[];for(let n=0;n<=e;n++)t.push(this.getPoint(n/e));return this.autoClose&&t.push(t[0]),t}getPoints(e=12){let t=[],n;for(let r=0,a=this.curves;r<a.length;r++){let s=a[r],o=s.isEllipseCurve?2*e:s.isLineCurve||s.isLineCurve3?1:s.isSplineCurve?e*s.points.length:e,c=s.getPoints(o);for(let l=0;l<c.length;l++){let h=c[l];n&&n.equals(h)||(t.push(h),n=h)}}return this.autoClose&&t.length>1&&!t[t.length-1].equals(t[0])&&t.push(t[0]),t}copy(e){super.copy(e),this.curves=[];for(let t=0,n=e.curves.length;t<n;t++){let r=e.curves[t];this.curves.push(r.clone())}return this.autoClose=e.autoClose,this}toJSON(){let e=super.toJSON();e.autoClose=this.autoClose,e.curves=[];for(let t=0,n=this.curves.length;t<n;t++){let r=this.curves[t];e.curves.push(r.toJSON())}return e}fromJSON(e){super.fromJSON(e),this.autoClose=e.autoClose,this.curves=[];for(let t=0,n=e.curves.length;t<n;t++){let r=e.curves[t];this.curves.push(new po[r.type]().fromJSON(r))}return this}},$a=class extends fo{constructor(e){super(),this.type="Path",this.currentPoint=new pe,e&&this.setFromPoints(e)}setFromPoints(e){this.moveTo(e[0].x,e[0].y);for(let t=1,n=e.length;t<n;t++)this.lineTo(e[t].x,e[t].y);return this}moveTo(e,t){return this.currentPoint.set(e,t),this}lineTo(e,t){let n=new Ya(this.currentPoint.clone(),new pe(e,t));return this.curves.push(n),this.currentPoint.set(e,t),this}quadraticCurveTo(e,t,n,r){let a=new Za(this.currentPoint.clone(),new pe(e,t),new pe(n,r));return this.curves.push(a),this.currentPoint.set(n,r),this}bezierCurveTo(e,t,n,r,a,s){let o=new qa(this.currentPoint.clone(),new pe(e,t),new pe(n,r),new pe(a,s));return this.curves.push(o),this.currentPoint.set(a,s),this}splineThru(e){let t=[this.currentPoint.clone()].concat(e),n=new Ka(t);return this.curves.push(n),this.currentPoint.copy(e[e.length-1]),this}arc(e,t,n,r,a,s){let o=this.currentPoint.x,c=this.currentPoint.y;return this.absarc(e+o,t+c,n,r,a,s),this}absarc(e,t,n,r,a,s){return this.absellipse(e,t,n,n,r,a,s),this}ellipse(e,t,n,r,a,s,o,c){let l=this.currentPoint.x,h=this.currentPoint.y;return this.absellipse(e+l,t+h,n,r,a,s,o,c),this}absellipse(e,t,n,r,a,s,o,c){let l=new ra(e,t,n,r,a,s,o,c);if(this.curves.length>0){let u=l.getPoint(0);u.equals(this.currentPoint)||this.lineTo(u.x,u.y)}this.curves.push(l);let h=l.getPoint(1);return this.currentPoint.copy(h),this}copy(e){return super.copy(e),this.currentPoint.copy(e.currentPoint),this}toJSON(){let e=super.toJSON();return e.currentPoint=this.currentPoint.toArray(),e}fromJSON(e){return super.fromJSON(e),this.currentPoint.fromArray(e.currentPoint),this}},Qa=class extends $a{constructor(e){super(e),this.uuid=br(),this.type="Shape",this.holes=[]}getPointsHoles(e){let t=[];for(let n=0,r=this.holes.length;n<r;n++)t[n]=this.holes[n].getPoints(e);return t}extractPoints(e){return{shape:this.getPoints(e),holes:this.getPointsHoles(e)}}copy(e){super.copy(e),this.holes=[];for(let t=0,n=e.holes.length;t<n;t++){let r=e.holes[t];this.holes.push(r.clone())}return this}toJSON(){let e=super.toJSON();e.uuid=this.uuid,e.holes=[];for(let t=0,n=this.holes.length;t<n;t++){let r=this.holes[t];e.holes.push(r.toJSON())}return e}fromJSON(e){super.fromJSON(e),this.uuid=e.uuid,this.holes=[];for(let t=0,n=e.holes.length;t<n;t++){let r=e.holes[t];this.holes.push(new $a().fromJSON(r))}return this}};function Cp(i,e,t=2){let n=e&&e.length,r=n?e[0]*t:i.length,a=ru(i,0,r,t,!0),s=[];if(!a||a.next===a.prev)return s;let o,c,l;if(n&&(a=(function(h,u,d,p){let m=[];for(let g=0,f=u.length;g<f;g++){let v=ru(h,u[g]*p,g<f-1?u[g+1]*p:h.length,p,!1);v===v.next&&(v.steiner=!0),m.push(Op(v))}m.sort(Up);for(let g=0;g<m.length;g++)d=Np(m[g],d);return d})(i,e,a,t)),i.length>80*t){o=1/0,c=1/0;let h=-1/0,u=-1/0;for(let d=t;d<r;d+=t){let p=i[d],m=i[d+1];p<o&&(o=p),m<c&&(c=m),p>h&&(h=p),m>u&&(u=m)}l=Math.max(h-o,u-c),l=l!==0?32767/l:0}return es(a,s,t,o,c,l,0),s}function ru(i,e,t,n,r){let a;if(r===(function(s,o,c,l){let h=0;for(let u=o,d=c-l;u<c;u+=l)h+=(s[d]-s[u])*(s[u+1]+s[d+1]),d=u;return h})(i,e,t,n)>0)for(let s=e;s<t;s+=n)a=au(s/n|0,i[s],i[s+1],a);else for(let s=t-n;s>=e;s-=n)a=au(s/n|0,i[s],i[s+1],a);return a&&aa(a,a.next)&&(ns(a),a=a.next),a}function mr(i,e){if(!i)return i;e||(e=i);let t,n=i;do if(t=!1,n.steiner||!aa(n,n.next)&&At(n.prev,n,n.next)!==0)n=n.next;else{if(ns(n),n=e=n.prev,n===n.next)break;t=!0}while(t||n!==e);return e}function es(i,e,t,n,r,a,s){if(!i)return;!s&&a&&(function(c,l,h,u){let d=c;do d.z===0&&(d.z=tc(d.x,d.y,l,h,u)),d.prevZ=d.prev,d.nextZ=d.next,d=d.next;while(d!==c);d.prevZ.nextZ=null,d.prevZ=null,(function(p){let m,g=1;do{let f,v=p;p=null;let _=null;for(m=0;v;){m++;let y=v,S=0;for(let R=0;R<g&&(S++,y=y.nextZ,y);R++);let w=g;for(;S>0||w>0&&y;)S!==0&&(w===0||!y||v.z<=y.z)?(f=v,v=v.nextZ,S--):(f=y,y=y.nextZ,w--),_?_.nextZ=f:p=f,f.prevZ=_,_=f;v=y}_.nextZ=null,g*=2}while(m>1)})(d)})(i,n,r,a);let o=i;for(;i.prev!==i.next;){let c=i.prev,l=i.next;if(a?Ip(i,n,r,a):Pp(i))e.push(c.i,i.i,l.i),ns(i),i=l.next,o=l.next;else if((i=l)===o){s?s===1?es(i=Lp(mr(i),e),e,t,n,r,a,2):s===2&&Dp(i,e,t,n,r,a):es(mr(i),e,t,n,r,a,1);break}}}function Pp(i){let e=i.prev,t=i,n=i.next;if(At(e,t,n)>=0)return!1;let r=e.x,a=t.x,s=n.x,o=e.y,c=t.y,l=n.y,h=Math.min(r,a,s),u=Math.min(o,c,l),d=Math.max(r,a,s),p=Math.max(o,c,l),m=n.next;for(;m!==e;){if(m.x>=h&&m.x<=d&&m.y>=u&&m.y<=p&&Ia(r,o,a,c,s,l,m.x,m.y)&&At(m.prev,m,m.next)>=0)return!1;m=m.next}return!0}function Ip(i,e,t,n){let r=i.prev,a=i,s=i.next;if(At(r,a,s)>=0)return!1;let o=r.x,c=a.x,l=s.x,h=r.y,u=a.y,d=s.y,p=Math.min(o,c,l),m=Math.min(h,u,d),g=Math.max(o,c,l),f=Math.max(h,u,d),v=tc(p,m,e,t,n),_=tc(g,f,e,t,n),y=i.prevZ,S=i.nextZ;for(;y&&y.z>=v&&S&&S.z<=_;){if(y.x>=p&&y.x<=g&&y.y>=m&&y.y<=f&&y!==r&&y!==s&&Ia(o,h,c,u,l,d,y.x,y.y)&&At(y.prev,y,y.next)>=0||(y=y.prevZ,S.x>=p&&S.x<=g&&S.y>=m&&S.y<=f&&S!==r&&S!==s&&Ia(o,h,c,u,l,d,S.x,S.y)&&At(S.prev,S,S.next)>=0))return!1;S=S.nextZ}for(;y&&y.z>=v;){if(y.x>=p&&y.x<=g&&y.y>=m&&y.y<=f&&y!==r&&y!==s&&Ia(o,h,c,u,l,d,y.x,y.y)&&At(y.prev,y,y.next)>=0)return!1;y=y.prevZ}for(;S&&S.z<=_;){if(S.x>=p&&S.x<=g&&S.y>=m&&S.y<=f&&S!==r&&S!==s&&Ia(o,h,c,u,l,d,S.x,S.y)&&At(S.prev,S,S.next)>=0)return!1;S=S.nextZ}return!0}function Lp(i,e){let t=i;do{let n=t.prev,r=t.next.next;!aa(n,r)&&ld(n,t,t.next,r)&&ts(n,r)&&ts(r,n)&&(e.push(n.i,t.i,r.i),ns(t),ns(t.next),t=i=r),t=t.next}while(t!==i);return mr(t)}function Dp(i,e,t,n,r,a){let s=i;do{let o=s.next.next;for(;o!==s.prev;){if(s.i!==o.i&&Bp(s,o)){let c=cd(s,o);return s=mr(s,s.next),c=mr(c,c.next),es(s,e,t,n,r,a,0),void es(c,e,t,n,r,a,0)}o=o.next}s=s.next}while(s!==i)}function Up(i,e){let t=i.x-e.x;return t===0&&(t=i.y-e.y,t===0)&&(t=(i.next.y-i.y)/(i.next.x-i.x)-(e.next.y-e.y)/(e.next.x-e.x)),t}function Np(i,e){let t=(function(r,a){let s=a,o=r.x,c=r.y,l,h=-1/0;if(aa(r,s))return s;do{if(aa(r,s.next))return s.next;if(c<=s.y&&c>=s.next.y&&s.next.y!==s.y){let g=s.x+(c-s.y)*(s.next.x-s.x)/(s.next.y-s.y);if(g<=o&&g>h&&(h=g,l=s.x<s.next.x?s:s.next,g===o))return l}s=s.next}while(s!==a);if(!l)return null;let u=l,d=l.x,p=l.y,m=1/0;s=l;do{if(o>=s.x&&s.x>=d&&o!==s.x&&od(c<p?o:h,c,d,p,c<p?h:o,c,s.x,s.y)){let g=Math.abs(c-s.y)/(o-s.x);ts(s,r)&&(g<m||g===m&&(s.x>l.x||s.x===l.x&&Fp(l,s)))&&(l=s,m=g)}s=s.next}while(s!==u);return l})(i,e);if(!t)return e;let n=cd(t,i);return mr(n,n.next),mr(t,t.next)}function Fp(i,e){return At(i.prev,i,e.prev)<0&&At(e.next,i,i.next)<0}function tc(i,e,t,n,r){return(i=1431655765&((i=858993459&((i=252645135&((i=16711935&((i=(i-t)*r|0)|i<<8))|i<<4))|i<<2))|i<<1))|(e=1431655765&((e=858993459&((e=252645135&((e=16711935&((e=(e-n)*r|0)|e<<8))|e<<4))|e<<2))|e<<1))<<1}function Op(i){let e=i,t=i;do(e.x<t.x||e.x===t.x&&e.y<t.y)&&(t=e),e=e.next;while(e!==i);return t}function od(i,e,t,n,r,a,s,o){return(r-s)*(e-o)>=(i-s)*(a-o)&&(i-s)*(n-o)>=(t-s)*(e-o)&&(t-s)*(a-o)>=(r-s)*(n-o)}function Ia(i,e,t,n,r,a,s,o){return!(i===s&&e===o)&&od(i,e,t,n,r,a,s,o)}function Bp(i,e){return i.next.i!==e.i&&i.prev.i!==e.i&&!(function(t,n){let r=t;do{if(r.i!==t.i&&r.next.i!==t.i&&r.i!==n.i&&r.next.i!==n.i&&ld(r,r.next,t,n))return!0;r=r.next}while(r!==t);return!1})(i,e)&&(ts(i,e)&&ts(e,i)&&(function(t,n){let r=t,a=!1,s=(t.x+n.x)/2,o=(t.y+n.y)/2;do r.y>o!=r.next.y>o&&r.next.y!==r.y&&s<(r.next.x-r.x)*(o-r.y)/(r.next.y-r.y)+r.x&&(a=!a),r=r.next;while(r!==t);return a})(i,e)&&(At(i.prev,i,e.prev)||At(i,e.prev,e))||aa(i,e)&&At(i.prev,i,i.next)>0&&At(e.prev,e,e.next)>0)}function At(i,e,t){return(e.y-i.y)*(t.x-e.x)-(e.x-i.x)*(t.y-e.y)}function aa(i,e){return i.x===e.x&&i.y===e.y}function ld(i,e,t,n){let r=Xs(At(i,e,t)),a=Xs(At(i,e,n)),s=Xs(At(t,n,i)),o=Xs(At(t,n,e));return r!==a&&s!==o||!(r!==0||!Ws(i,t,e))||!(a!==0||!Ws(i,n,e))||!(s!==0||!Ws(t,i,n))||!(o!==0||!Ws(t,e,n))}function Ws(i,e,t){return e.x<=Math.max(i.x,t.x)&&e.x>=Math.min(i.x,t.x)&&e.y<=Math.max(i.y,t.y)&&e.y>=Math.min(i.y,t.y)}function Xs(i){return i>0?1:i<0?-1:0}function ts(i,e){return At(i.prev,i,i.next)<0?At(i,e,i.next)>=0&&At(i,i.prev,e)>=0:At(i,e,i.prev)<0||At(i,i.next,e)<0}function cd(i,e){let t=nc(i.i,i.x,i.y),n=nc(e.i,e.x,e.y),r=i.next,a=e.prev;return i.next=e,e.prev=i,t.next=r,r.prev=t,n.next=t,t.prev=n,a.next=n,n.prev=a,n}function au(i,e,t,n){let r=nc(i,e,t);return n?(r.next=n.next,r.prev=n,n.next.prev=r,n.next=r):(r.prev=r,r.next=r),r}function ns(i){i.next.prev=i.prev,i.prev.next=i.next,i.prevZ&&(i.prevZ.nextZ=i.nextZ),i.nextZ&&(i.nextZ.prevZ=i.prevZ)}function nc(i,e,t){return{i,x:e,y:t,prev:null,next:null,z:0,prevZ:null,nextZ:null,steiner:!1}}var ic=class{static triangulate(e,t,n=2){return Cp(e,t,n)}},ni=class i{static area(e){let t=e.length,n=0;for(let r=t-1,a=0;a<t;r=a++)n+=e[r].x*e[a].y-e[a].x*e[r].y;return .5*n}static isClockWise(e){return i.area(e)<0}static triangulateShape(e,t){let n=[],r=[],a=[];su(e),ou(n,e);let s=e.length;t.forEach(su);for(let c=0;c<t.length;c++)r.push(s),s+=t[c].length,ou(n,t[c]);let o=ic.triangulate(n,r);for(let c=0;c<o.length;c+=3)a.push(o.slice(c,c+3));return a}};function su(i){let e=i.length;e>2&&i[e-1].equals(i[0])&&i.pop()}function ou(i,e){for(let t=0;t<e.length;t++)i.push(e[t].x),i.push(e[t].y)}var mo=class i extends mt{constructor(e=new Qa([new pe(.5,.5),new pe(-.5,.5),new pe(-.5,-.5),new pe(.5,-.5)]),t={}){super(),this.type="ExtrudeGeometry",this.parameters={shapes:e,options:t},e=Array.isArray(e)?e:[e];let n=this,r=[],a=[];for(let o=0,c=e.length;o<c;o++)s(e[o]);function s(o){let c=[],l=t.curveSegments!==void 0?t.curveSegments:12,h=t.steps!==void 0?t.steps:1,u=t.depth!==void 0?t.depth:1,d=t.bevelEnabled===void 0||t.bevelEnabled,p=t.bevelThickness!==void 0?t.bevelThickness:.2,m=t.bevelSize!==void 0?t.bevelSize:p-.1,g=t.bevelOffset!==void 0?t.bevelOffset:0,f=t.bevelSegments!==void 0?t.bevelSegments:3,v=t.extrudePath,_=t.UVGenerator!==void 0?t.UVGenerator:kp,y,S,w,R,B,G=!1;v&&(y=v.getSpacedPoints(h),G=!0,d=!1,S=v.computeFrenetFrames(h,!1),w=new E,R=new E,B=new E),d||(f=0,p=0,m=0,g=0);let D=o.extractPoints(l),J=D.shape,K=D.holes;if(!ni.isClockWise(J)){J=J.reverse();for(let U=0,M=K.length;U<M;U++){let A=K[U];ni.isClockWise(A)&&(K[U]=A.reverse())}}function V(U){let M=10000000000000001e-36,A=U[0];for(let F=1;F<=U.length;F++){let P=F%U.length,te=U[P],j=te.x-A.x,q=te.y-A.y,he=j*j+q*q,Se=Math.max(Math.abs(te.x),Math.abs(te.y),Math.abs(A.x),Math.abs(A.y));he<=M*Se*Se?(U.splice(P,1),F--):A=te}}V(J),K.forEach(V);let se=K.length,X=J;for(let U=0;U<se;U++){let M=K[U];J=J.concat(M)}function ee(U,M,A){return M||console.error("THREE.ExtrudeGeometry: vec does not exist"),U.clone().addScaledVector(M,A)}let Q=J.length;function me(U,M,A){let F,P,te,j=U.x-M.x,q=U.y-M.y,he=A.x-U.x,Se=A.y-U.y,ue=j*j+q*q,Re=j*Se-q*he;if(Math.abs(Re)>Number.EPSILON){let De=Math.sqrt(ue),Te=Math.sqrt(he*he+Se*Se),Ue=M.x-q/De,We=M.y+j/De,it=((A.x-Se/Te-Ue)*Se-(A.y+he/Te-We)*he)/(j*Se-q*he);F=Ue+j*it-U.x,P=We+q*it-U.y;let Ee=F*F+P*P;if(Ee<=2)return new pe(F,P);te=Math.sqrt(Ee/2)}else{let De=!1;j>Number.EPSILON?he>Number.EPSILON&&(De=!0):j<-Number.EPSILON?he<-Number.EPSILON&&(De=!0):Math.sign(q)===Math.sign(Se)&&(De=!0),De?(F=-q,P=j,te=Math.sqrt(ue)):(F=j,P=q,te=Math.sqrt(ue/2))}return new pe(F/te,P/te)}let ae=[];for(let U=0,M=X.length,A=M-1,F=U+1;U<M;U++,A++,F++)A===M&&(A=0),F===M&&(F=0),ae[U]=me(X[U],X[A],X[F]);let be=[],Be,Ie,Ne=ae.concat();for(let U=0,M=se;U<M;U++){let A=K[U];Be=[];for(let F=0,P=A.length,te=P-1,j=F+1;F<P;F++,te++,j++)te===P&&(te=0),j===P&&(j=0),Be[F]=me(A[F],A[te],A[j]);be.push(Be),Ne=Ne.concat(Be)}if(f===0)Ie=ni.triangulateShape(X,K);else{let U=[],M=[];for(let A=0;A<f;A++){let F=A/f,P=p*Math.cos(F*Math.PI/2),te=m*Math.sin(F*Math.PI/2)+g;for(let j=0,q=X.length;j<q;j++){let he=ee(X[j],ae[j],te);Oe(he.x,he.y,-P),F===0&&U.push(he)}for(let j=0,q=se;j<q;j++){let he=K[j];Be=be[j];let Se=[];for(let ue=0,Re=he.length;ue<Re;ue++){let De=ee(he[ue],Be[ue],te);Oe(De.x,De.y,-P),F===0&&Se.push(De)}F===0&&M.push(Se)}}Ie=ni.triangulateShape(U,M)}let le=Ie.length,re=m+g;for(let U=0;U<Q;U++){let M=d?ee(J[U],Ne[U],re):J[U];G?(R.copy(S.normals[0]).multiplyScalar(M.x),w.copy(S.binormals[0]).multiplyScalar(M.y),B.copy(y[0]).add(R).add(w),Oe(B.x,B.y,B.z)):Oe(M.x,M.y,0)}for(let U=1;U<=h;U++)for(let M=0;M<Q;M++){let A=d?ee(J[M],Ne[M],re):J[M];G?(R.copy(S.normals[U]).multiplyScalar(A.x),w.copy(S.binormals[U]).multiplyScalar(A.y),B.copy(y[U]).add(R).add(w),Oe(B.x,B.y,B.z)):Oe(A.x,A.y,u/h*U)}for(let U=f-1;U>=0;U--){let M=U/f,A=p*Math.cos(M*Math.PI/2),F=m*Math.sin(M*Math.PI/2)+g;for(let P=0,te=X.length;P<te;P++){let j=ee(X[P],ae[P],F);Oe(j.x,j.y,u+A)}for(let P=0,te=K.length;P<te;P++){let j=K[P];Be=be[P];for(let q=0,he=j.length;q<he;q++){let Se=ee(j[q],Be[q],F);G?Oe(Se.x,Se.y+y[h-1].y,y[h-1].x+A):Oe(Se.x,Se.y,u+A)}}}function ne(U,M){let A=U.length;for(;--A>=0;){let F=A,P=A-1;P<0&&(P=U.length-1);for(let te=0,j=h+2*f;te<j;te++){let q=Q*te,he=Q*(te+1);T(M+F+q,M+P+q,M+P+he,M+F+he)}}}function Oe(U,M,A){c.push(U),c.push(M),c.push(A)}function Ge(U,M,A){b(U),b(M),b(A);let F=r.length/3,P=_.generateTopUV(n,r,F-3,F-2,F-1);H(P[0]),H(P[1]),H(P[2])}function T(U,M,A,F){b(U),b(M),b(F),b(M),b(A),b(F);let P=r.length/3,te=_.generateSideWallUV(n,r,P-6,P-3,P-2,P-1);H(te[0]),H(te[1]),H(te[3]),H(te[1]),H(te[2]),H(te[3])}function b(U){r.push(c[3*U+0]),r.push(c[3*U+1]),r.push(c[3*U+2])}function H(U){a.push(U.x),a.push(U.y)}(function(){let U=r.length/3;if(d){let M=0,A=Q*M;for(let F=0;F<le;F++){let P=Ie[F];Ge(P[2]+A,P[1]+A,P[0]+A)}M=h+2*f,A=Q*M;for(let F=0;F<le;F++){let P=Ie[F];Ge(P[0]+A,P[1]+A,P[2]+A)}}else{for(let M=0;M<le;M++){let A=Ie[M];Ge(A[2],A[1],A[0])}for(let M=0;M<le;M++){let A=Ie[M];Ge(A[0]+Q*h,A[1]+Q*h,A[2]+Q*h)}}n.addGroup(U,r.length/3-U,0)})(),(function(){let U=r.length/3,M=0;ne(X,M),M+=X.length;for(let A=0,F=K.length;A<F;A++){let P=K[A];ne(P,M),M+=P.length}n.addGroup(U,r.length/3-U,1)})()}this.setAttribute("position",new Ye(r,3)),this.setAttribute("uv",new Ye(a,2)),this.computeVertexNormals()}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}toJSON(){let e=super.toJSON();return(function(t,n,r){if(r.shapes=[],Array.isArray(t))for(let a=0,s=t.length;a<s;a++){let o=t[a];r.shapes.push(o.uuid)}else r.shapes.push(t.uuid);return r.options=Object.assign({},n),n.extrudePath!==void 0&&(r.options.extrudePath=n.extrudePath.toJSON()),r})(this.parameters.shapes,this.parameters.options,e)}static fromJSON(e,t){let n=[];for(let a=0,s=e.shapes.length;a<s;a++){let o=t[e.shapes[a]];n.push(o)}let r=e.options.extrudePath;return r!==void 0&&(e.options.extrudePath=new po[r.type]().fromJSON(r)),new i(n,e.options)}},kp={generateTopUV:function(i,e,t,n,r){let a=e[3*t],s=e[3*t+1],o=e[3*n],c=e[3*n+1],l=e[3*r],h=e[3*r+1];return[new pe(a,s),new pe(o,c),new pe(l,h)]},generateSideWallUV:function(i,e,t,n,r,a){let s=e[3*t],o=e[3*t+1],c=e[3*t+2],l=e[3*n],h=e[3*n+1],u=e[3*n+2],d=e[3*r],p=e[3*r+1],m=e[3*r+2],g=e[3*a],f=e[3*a+1],v=e[3*a+2];return Math.abs(o-h)<Math.abs(s-l)?[new pe(s,1-c),new pe(l,1-u),new pe(d,1-m),new pe(g,1-v)]:[new pe(o,1-c),new pe(h,1-u),new pe(p,1-m),new pe(f,1-v)]}},go=class i extends Zi{constructor(e=1,t=0){let n=(1+Math.sqrt(5))/2;super([-1,n,0,1,n,0,-1,-n,0,1,-n,0,0,-1,n,0,1,n,0,-1,-n,0,1,-n,n,0,-1,n,0,1,-n,0,-1,-n,0,1],[0,11,5,0,5,1,0,1,7,0,7,10,0,10,11,1,5,9,5,11,4,11,10,2,10,7,6,7,1,8,3,9,4,3,4,2,3,2,6,3,6,8,3,8,9,4,9,5,2,4,11,6,2,10,8,6,7,9,8,1],e,t),this.type="IcosahedronGeometry",this.parameters={radius:e,detail:t}}static fromJSON(e){return new i(e.radius,e.detail)}},Ji=class i extends mt{constructor(e=[new pe(0,-.5),new pe(.5,0),new pe(0,.5)],t=12,n=0,r=2*Math.PI){super(),this.type="LatheGeometry",this.parameters={points:e,segments:t,phiStart:n,phiLength:r},t=Math.floor(t),r=at(r,0,2*Math.PI);let a=[],s=[],o=[],c=[],l=[],h=1/t,u=new E,d=new pe,p=new E,m=new E,g=new E,f=0,v=0;for(let _=0;_<=e.length-1;_++)switch(_){case 0:f=e[_+1].x-e[_].x,v=e[_+1].y-e[_].y,p.x=1*v,p.y=-f,p.z=0*v,g.copy(p),p.normalize(),c.push(p.x,p.y,p.z);break;case e.length-1:c.push(g.x,g.y,g.z);break;default:f=e[_+1].x-e[_].x,v=e[_+1].y-e[_].y,p.x=1*v,p.y=-f,p.z=0*v,m.copy(p),p.x+=g.x,p.y+=g.y,p.z+=g.z,p.normalize(),c.push(p.x,p.y,p.z),g.copy(m)}for(let _=0;_<=t;_++){let y=n+_*h*r,S=Math.sin(y),w=Math.cos(y);for(let R=0;R<=e.length-1;R++){u.x=e[R].x*S,u.y=e[R].y,u.z=e[R].x*w,s.push(u.x,u.y,u.z),d.x=_/t,d.y=R/(e.length-1),o.push(d.x,d.y);let B=c[3*R+0]*S,G=c[3*R+1],D=c[3*R+0]*w;l.push(B,G,D)}}for(let _=0;_<t;_++)for(let y=0;y<e.length-1;y++){let S=y+_*e.length,w=S,R=S+e.length,B=S+e.length+1,G=S+1;a.push(w,R,G),a.push(B,G,R)}this.setIndex(a),this.setAttribute("position",new Ye(s,3)),this.setAttribute("uv",new Ye(o,2)),this.setAttribute("normal",new Ye(l,3))}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}static fromJSON(e){return new i(e.points,e.segments,e.phiStart,e.phiLength)}},vo=class i extends Zi{constructor(e=1,t=0){super([1,0,0,-1,0,0,0,1,0,0,-1,0,0,0,1,0,0,-1],[0,2,4,0,4,3,0,3,5,0,5,2,1,2,5,1,5,3,1,3,4,1,4,2],e,t),this.type="OctahedronGeometry",this.parameters={radius:e,detail:t}}static fromJSON(e){return new i(e.radius,e.detail)}},on=class i extends mt{constructor(e=1,t=1,n=1,r=1){super(),this.type="PlaneGeometry",this.parameters={width:e,height:t,widthSegments:n,heightSegments:r};let a=e/2,s=t/2,o=Math.floor(n),c=Math.floor(r),l=o+1,h=c+1,u=e/o,d=t/c,p=[],m=[],g=[],f=[];for(let v=0;v<h;v++){let _=v*d-s;for(let y=0;y<l;y++){let S=y*u-a;m.push(S,-_,0),g.push(0,0,1),f.push(y/o),f.push(1-v/c)}}for(let v=0;v<c;v++)for(let _=0;_<o;_++){let y=_+l*v,S=_+l*(v+1),w=_+1+l*(v+1),R=_+1+l*v;p.push(y,S,R),p.push(S,w,R)}this.setIndex(p),this.setAttribute("position",new Ye(m,3)),this.setAttribute("normal",new Ye(g,3)),this.setAttribute("uv",new Ye(f,2))}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}static fromJSON(e){return new i(e.width,e.height,e.widthSegments,e.heightSegments)}},_o=class i extends mt{constructor(e=.5,t=1,n=32,r=1,a=0,s=2*Math.PI){super(),this.type="RingGeometry",this.parameters={innerRadius:e,outerRadius:t,thetaSegments:n,phiSegments:r,thetaStart:a,thetaLength:s},n=Math.max(3,n);let o=[],c=[],l=[],h=[],u=e,d=(t-e)/(r=Math.max(1,r)),p=new E,m=new pe;for(let g=0;g<=r;g++){for(let f=0;f<=n;f++){let v=a+f/n*s;p.x=u*Math.cos(v),p.y=u*Math.sin(v),c.push(p.x,p.y,p.z),l.push(0,0,1),m.x=(p.x/t+1)/2,m.y=(p.y/t+1)/2,h.push(m.x,m.y)}u+=d}for(let g=0;g<r;g++){let f=g*(n+1);for(let v=0;v<n;v++){let _=v+f,y=_,S=_+n+1,w=_+n+2,R=_+1;o.push(y,S,R),o.push(S,w,R)}}this.setIndex(o),this.setAttribute("position",new Ye(c,3)),this.setAttribute("normal",new Ye(l,3)),this.setAttribute("uv",new Ye(h,2))}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}static fromJSON(e){return new i(e.innerRadius,e.outerRadius,e.thetaSegments,e.phiSegments,e.thetaStart,e.thetaLength)}},yo=class i extends mt{constructor(e=new Qa([new pe(0,.5),new pe(-.5,-.5),new pe(.5,-.5)]),t=12){super(),this.type="ShapeGeometry",this.parameters={shapes:e,curveSegments:t};let n=[],r=[],a=[],s=[],o=0,c=0;if(Array.isArray(e)===!1)l(e);else for(let h=0;h<e.length;h++)l(e[h]),this.addGroup(o,c,h),o+=c,c=0;function l(h){let u=r.length/3,d=h.extractPoints(t),p=d.shape,m=d.holes;ni.isClockWise(p)===!1&&(p=p.reverse());for(let f=0,v=m.length;f<v;f++){let _=m[f];ni.isClockWise(_)===!0&&(m[f]=_.reverse())}let g=ni.triangulateShape(p,m);for(let f=0,v=m.length;f<v;f++){let _=m[f];p=p.concat(_)}for(let f=0,v=p.length;f<v;f++){let _=p[f];r.push(_.x,_.y,0),a.push(0,0,1),s.push(_.x,_.y)}for(let f=0,v=g.length;f<v;f++){let _=g[f],y=_[0]+u,S=_[1]+u,w=_[2]+u;n.push(y,S,w),c+=3}}this.setIndex(n),this.setAttribute("position",new Ye(r,3)),this.setAttribute("normal",new Ye(a,3)),this.setAttribute("uv",new Ye(s,2))}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}toJSON(){let e=super.toJSON();return(function(t,n){if(n.shapes=[],Array.isArray(t))for(let r=0,a=t.length;r<a;r++){let s=t[r];n.shapes.push(s.uuid)}else n.shapes.push(t.uuid);return n})(this.parameters.shapes,e)}static fromJSON(e,t){let n=[];for(let r=0,a=e.shapes.length;r<a;r++){let s=t[e.shapes[r]];n.push(s)}return new i(n,e.curveSegments)}},Wn=class i extends mt{constructor(e=1,t=32,n=16,r=0,a=2*Math.PI,s=0,o=Math.PI){super(),this.type="SphereGeometry",this.parameters={radius:e,widthSegments:t,heightSegments:n,phiStart:r,phiLength:a,thetaStart:s,thetaLength:o},t=Math.max(3,Math.floor(t)),n=Math.max(2,Math.floor(n));let c=Math.min(s+o,Math.PI),l=0,h=[],u=new E,d=new E,p=[],m=[],g=[],f=[];for(let v=0;v<=n;v++){let _=[],y=v/n,S=0;v===0&&s===0?S=.5/t:v===n&&c===Math.PI&&(S=-.5/t);for(let w=0;w<=t;w++){let R=w/t;u.x=-e*Math.cos(r+R*a)*Math.sin(s+y*o),u.y=e*Math.cos(s+y*o),u.z=e*Math.sin(r+R*a)*Math.sin(s+y*o),m.push(u.x,u.y,u.z),d.copy(u).normalize(),g.push(d.x,d.y,d.z),f.push(R+S,1-y),_.push(l++)}h.push(_)}for(let v=0;v<n;v++)for(let _=0;_<t;_++){let y=h[v][_+1],S=h[v][_],w=h[v+1][_],R=h[v+1][_+1];(v!==0||s>0)&&p.push(y,S,R),(v!==n-1||c<Math.PI)&&p.push(S,w,R)}this.setIndex(p),this.setAttribute("position",new Ye(m,3)),this.setAttribute("normal",new Ye(g,3)),this.setAttribute("uv",new Ye(f,2))}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}static fromJSON(e){return new i(e.radius,e.widthSegments,e.heightSegments,e.phiStart,e.phiLength,e.thetaStart,e.thetaLength)}},xo=class i extends Zi{constructor(e=1,t=0){super([1,1,1,-1,-1,1,-1,1,-1,1,-1,-1],[2,1,0,0,3,2,1,3,0,2,3,1],e,t),this.type="TetrahedronGeometry",this.parameters={radius:e,detail:t}}static fromJSON(e){return new i(e.radius,e.detail)}},Ki=class i extends mt{constructor(e=1,t=.4,n=12,r=48,a=2*Math.PI){super(),this.type="TorusGeometry",this.parameters={radius:e,tube:t,radialSegments:n,tubularSegments:r,arc:a},n=Math.floor(n),r=Math.floor(r);let s=[],o=[],c=[],l=[],h=new E,u=new E,d=new E;for(let p=0;p<=n;p++)for(let m=0;m<=r;m++){let g=m/r*a,f=p/n*Math.PI*2;u.x=(e+t*Math.cos(f))*Math.cos(g),u.y=(e+t*Math.cos(f))*Math.sin(g),u.z=t*Math.sin(f),o.push(u.x,u.y,u.z),h.x=e*Math.cos(g),h.y=e*Math.sin(g),d.subVectors(u,h).normalize(),c.push(d.x,d.y,d.z),l.push(m/r),l.push(p/n)}for(let p=1;p<=n;p++)for(let m=1;m<=r;m++){let g=(r+1)*p+m-1,f=(r+1)*(p-1)+m-1,v=(r+1)*(p-1)+m,_=(r+1)*p+m;s.push(g,f,_),s.push(f,v,_)}this.setIndex(s),this.setAttribute("position",new Ye(o,3)),this.setAttribute("normal",new Ye(c,3)),this.setAttribute("uv",new Ye(l,2))}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}static fromJSON(e){return new i(e.radius,e.tube,e.radialSegments,e.tubularSegments,e.arc)}},Mo=class i extends mt{constructor(e=1,t=.4,n=64,r=8,a=2,s=3){super(),this.type="TorusKnotGeometry",this.parameters={radius:e,tube:t,tubularSegments:n,radialSegments:r,p:a,q:s},n=Math.floor(n),r=Math.floor(r);let o=[],c=[],l=[],h=[],u=new E,d=new E,p=new E,m=new E,g=new E,f=new E,v=new E;for(let y=0;y<=n;++y){let S=y/n*a*Math.PI*2;_(S,a,s,e,p),_(S+.01,a,s,e,m),f.subVectors(m,p),v.addVectors(m,p),g.crossVectors(f,v),v.crossVectors(g,f),g.normalize(),v.normalize();for(let w=0;w<=r;++w){let R=w/r*Math.PI*2,B=-t*Math.cos(R),G=t*Math.sin(R);u.x=p.x+(B*v.x+G*g.x),u.y=p.y+(B*v.y+G*g.y),u.z=p.z+(B*v.z+G*g.z),c.push(u.x,u.y,u.z),d.subVectors(u,p).normalize(),l.push(d.x,d.y,d.z),h.push(y/n),h.push(w/r)}}for(let y=1;y<=n;y++)for(let S=1;S<=r;S++){let w=(r+1)*(y-1)+(S-1),R=(r+1)*y+(S-1),B=(r+1)*y+S,G=(r+1)*(y-1)+S;o.push(w,R,G),o.push(R,B,G)}function _(y,S,w,R,B){let G=Math.cos(y),D=Math.sin(y),J=w/S*y,K=Math.cos(J);B.x=R*(2+K)*.5*G,B.y=R*(2+K)*D*.5,B.z=R*Math.sin(J)*.5}this.setIndex(o),this.setAttribute("position",new Ye(c,3)),this.setAttribute("normal",new Ye(l,3)),this.setAttribute("uv",new Ye(h,2))}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}static fromJSON(e){return new i(e.radius,e.tube,e.tubularSegments,e.radialSegments,e.p,e.q)}},So=class i extends mt{constructor(e=new Ja(new E(-1,-1,0),new E(-1,1,0),new E(1,1,0)),t=64,n=1,r=8,a=!1){super(),this.type="TubeGeometry",this.parameters={path:e,tubularSegments:t,radius:n,radialSegments:r,closed:a};let s=e.computeFrenetFrames(t,a);this.tangents=s.tangents,this.normals=s.normals,this.binormals=s.binormals;let o=new E,c=new E,l=new pe,h=new E,u=[],d=[],p=[],m=[];function g(f){h=e.getPointAt(f/t,h);let v=s.normals[f],_=s.binormals[f];for(let y=0;y<=r;y++){let S=y/r*Math.PI*2,w=Math.sin(S),R=-Math.cos(S);c.x=R*v.x+w*_.x,c.y=R*v.y+w*_.y,c.z=R*v.z+w*_.z,c.normalize(),d.push(c.x,c.y,c.z),o.x=h.x+n*c.x,o.y=h.y+n*c.y,o.z=h.z+n*c.z,u.push(o.x,o.y,o.z)}}(function(){for(let f=0;f<t;f++)g(f);g(a===!1?t:0),(function(){for(let f=0;f<=t;f++)for(let v=0;v<=r;v++)l.x=f/t,l.y=v/r,p.push(l.x,l.y)})(),(function(){for(let f=1;f<=t;f++)for(let v=1;v<=r;v++){let _=(r+1)*(f-1)+(v-1),y=(r+1)*f+(v-1),S=(r+1)*f+v,w=(r+1)*(f-1)+v;m.push(_,y,w),m.push(y,S,w)}})()})(),this.setIndex(m),this.setAttribute("position",new Ye(u,3)),this.setAttribute("normal",new Ye(d,3)),this.setAttribute("uv",new Ye(p,2))}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}toJSON(){let e=super.toJSON();return e.path=this.parameters.path.toJSON(),e}static fromJSON(e){return new i(new po[e.path.type]().fromJSON(e.path),e.tubularSegments,e.radius,e.radialSegments,e.closed)}},bo=class extends mt{constructor(e=null){if(super(),this.type="WireframeGeometry",this.parameters={geometry:e},e!==null){let t=[],n=new Set,r=new E,a=new E;if(e.index!==null){let s=e.attributes.position,o=e.index,c=e.groups;c.length===0&&(c=[{start:0,count:o.count,materialIndex:0}]);for(let l=0,h=c.length;l<h;++l){let u=c[l],d=u.start;for(let p=d,m=d+u.count;p<m;p+=3)for(let g=0;g<3;g++){let f=o.getX(p+g),v=o.getX(p+(g+1)%3);r.fromBufferAttribute(s,f),a.fromBufferAttribute(s,v),lu(r,a,n)===!0&&(t.push(r.x,r.y,r.z),t.push(a.x,a.y,a.z))}}}else{let s=e.attributes.position;for(let o=0,c=s.count/3;o<c;o++)for(let l=0;l<3;l++){let h=3*o+l,u=3*o+(l+1)%3;r.fromBufferAttribute(s,h),a.fromBufferAttribute(s,u),lu(r,a,n)===!0&&(t.push(r.x,r.y,r.z),t.push(a.x,a.y,a.z))}}this.setAttribute("position",new Ye(t,3))}}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}};function lu(i,e,t){let n=`${i.x},${i.y},${i.z}-${e.x},${e.y},${e.z}`,r=`${e.x},${e.y},${e.z}-${i.x},${i.y},${i.z}`;return t.has(n)!==!0&&t.has(r)!==!0&&(t.add(n),t.add(r),!0)}var B0=Object.freeze({__proto__:null,BoxGeometry:sn,CapsuleGeometry:ro,CircleGeometry:Ci,ConeGeometry:ao,CylinderGeometry:gt,DodecahedronGeometry:so,EdgesGeometry:oo,ExtrudeGeometry:mo,IcosahedronGeometry:go,LatheGeometry:Ji,OctahedronGeometry:vo,PlaneGeometry:on,PolyhedronGeometry:Zi,RingGeometry:_o,ShapeGeometry:yo,SphereGeometry:Wn,TetrahedronGeometry:xo,TorusGeometry:Ki,TorusKnotGeometry:Mo,TubeGeometry:So,WireframeGeometry:bo});var st=class extends Ai{constructor(e){super(),this.isMeshStandardMaterial=!0,this.type="MeshStandardMaterial",this.defines={STANDARD:""},this.color=new Ve(16777215),this.roughness=1,this.metalness=0,this.map=null,this.lightMap=null,this.lightMapIntensity=1,this.aoMap=null,this.aoMapIntensity=1,this.emissive=new Ve(0),this.emissiveIntensity=1,this.emissiveMap=null,this.bumpMap=null,this.bumpScale=1,this.normalMap=null,this.normalMapType=0,this.normalScale=new pe(1,1),this.displacementMap=null,this.displacementScale=1,this.displacementBias=0,this.roughnessMap=null,this.metalnessMap=null,this.alphaMap=null,this.envMap=null,this.envMapRotation=new an,this.envMapIntensity=1,this.wireframe=!1,this.wireframeLinewidth=1,this.wireframeLinecap="round",this.wireframeLinejoin="round",this.flatShading=!1,this.fog=!0,this.setValues(e)}copy(e){return super.copy(e),this.defines={STANDARD:""},this.color.copy(e.color),this.roughness=e.roughness,this.metalness=e.metalness,this.map=e.map,this.lightMap=e.lightMap,this.lightMapIntensity=e.lightMapIntensity,this.aoMap=e.aoMap,this.aoMapIntensity=e.aoMapIntensity,this.emissive.copy(e.emissive),this.emissiveMap=e.emissiveMap,this.emissiveIntensity=e.emissiveIntensity,this.bumpMap=e.bumpMap,this.bumpScale=e.bumpScale,this.normalMap=e.normalMap,this.normalMapType=e.normalMapType,this.normalScale.copy(e.normalScale),this.displacementMap=e.displacementMap,this.displacementScale=e.displacementScale,this.displacementBias=e.displacementBias,this.roughnessMap=e.roughnessMap,this.metalnessMap=e.metalnessMap,this.alphaMap=e.alphaMap,this.envMap=e.envMap,this.envMapRotation.copy(e.envMapRotation),this.envMapIntensity=e.envMapIntensity,this.wireframe=e.wireframe,this.wireframeLinewidth=e.wireframeLinewidth,this.wireframeLinecap=e.wireframeLinecap,this.wireframeLinejoin=e.wireframeLinejoin,this.flatShading=e.flatShading,this.fog=e.fog,this}};var To=class extends Ai{constructor(e){super(),this.isMeshDepthMaterial=!0,this.type="MeshDepthMaterial",this.depthPacking=3200,this.map=null,this.alphaMap=null,this.displacementMap=null,this.displacementScale=1,this.displacementBias=0,this.wireframe=!1,this.wireframeLinewidth=1,this.setValues(e)}copy(e){return super.copy(e),this.depthPacking=e.depthPacking,this.map=e.map,this.alphaMap=e.alphaMap,this.displacementMap=e.displacementMap,this.displacementScale=e.displacementScale,this.displacementBias=e.displacementBias,this.wireframe=e.wireframe,this.wireframeLinewidth=e.wireframeLinewidth,this}},Eo=class extends Ai{constructor(e){super(),this.isMeshDistanceMaterial=!0,this.type="MeshDistanceMaterial",this.map=null,this.alphaMap=null,this.displacementMap=null,this.displacementScale=1,this.displacementBias=0,this.setValues(e)}copy(e){return super.copy(e),this.map=e.map,this.alphaMap=e.alphaMap,this.displacementMap=e.displacementMap,this.displacementScale=e.displacementScale,this.displacementBias=e.displacementBias,this}};function js(i,e){return i&&i.constructor!==e?typeof e.BYTES_PER_ELEMENT=="number"?new e(i):Array.prototype.slice.call(i):i}function zp(i){return ArrayBuffer.isView(i)&&!(i instanceof DataView)}var gr=class{constructor(e,t,n,r){this.parameterPositions=e,this._cachedIndex=0,this.resultBuffer=r!==void 0?r:new t.constructor(n),this.sampleValues=t,this.valueSize=n,this.settings=null,this.DefaultSettings_={}}evaluate(e){let t=this.parameterPositions,n=this._cachedIndex,r=t[n],a=t[n-1];n:{e:{let s;t:{i:if(!(e<r)){for(let o=n+2;;){if(r===void 0){if(e<a)break i;return n=t.length,this._cachedIndex=n,this.copySampleValue_(n-1)}if(n===o)break;if(a=r,r=t[++n],e<r)break e}s=t.length;break t}if(!(e>=a)){let o=t[1];e<o&&(n=2,a=o);for(let c=n-2;;){if(a===void 0)return this._cachedIndex=0,this.copySampleValue_(0);if(n===c)break;if(r=a,a=t[--n-1],e>=a)break e}s=n,n=0;break t}break n}for(;n<s;){let o=n+s>>>1;e<t[o]?s=o:n=o+1}if(r=t[n],a=t[n-1],a===void 0)return this._cachedIndex=0,this.copySampleValue_(0);if(r===void 0)return n=t.length,this._cachedIndex=n,this.copySampleValue_(n-1)}this._cachedIndex=n,this.intervalChanged_(n,a,r)}return this.interpolate_(n,a,e,r)}getSettings_(){return this.settings||this.DefaultSettings_}copySampleValue_(e){let t=this.resultBuffer,n=this.sampleValues,r=this.valueSize,a=e*r;for(let s=0;s!==r;++s)t[s]=n[a+s];return t}interpolate_(){throw new Error("call to abstract method")}intervalChanged_(){}},wo=class extends gr{constructor(e,t,n,r){super(e,t,n,r),this._weightPrev=-0,this._offsetPrev=-0,this._weightNext=-0,this._offsetNext=-0,this.DefaultSettings_={endingStart:Yl,endingEnd:Yl}}intervalChanged_(e,t,n){let r=this.parameterPositions,a=e-2,s=e+1,o=r[a],c=r[s];if(o===void 0)switch(this.getSettings_().endingStart){case Zl:a=e,o=2*t-n;break;case Jl:a=r.length-2,o=t+r[a]-r[a+1];break;default:a=e,o=n}if(c===void 0)switch(this.getSettings_().endingEnd){case Zl:s=e,c=2*n-t;break;case Jl:s=1,c=n+r[1]-r[0];break;default:s=e-1,c=t}let l=.5*(n-t),h=this.valueSize;this._weightPrev=l/(t-o),this._weightNext=l/(c-n),this._offsetPrev=a*h,this._offsetNext=s*h}interpolate_(e,t,n,r){let a=this.resultBuffer,s=this.sampleValues,o=this.valueSize,c=e*o,l=c-o,h=this._offsetPrev,u=this._offsetNext,d=this._weightPrev,p=this._weightNext,m=(n-t)/(r-t),g=m*m,f=g*m,v=-d*f+2*d*g-d*m,_=(1+d)*f+(-1.5-2*d)*g+(-.5+d)*m+1,y=(-1-p)*f+(1.5+p)*g+.5*m,S=p*f-p*g;for(let w=0;w!==o;++w)a[w]=v*s[h+w]+_*s[l+w]+y*s[c+w]+S*s[u+w];return a}},Ao=class extends gr{constructor(e,t,n,r){super(e,t,n,r)}interpolate_(e,t,n,r){let a=this.resultBuffer,s=this.sampleValues,o=this.valueSize,c=e*o,l=c-o,h=(n-t)/(r-t),u=1-h;for(let d=0;d!==o;++d)a[d]=s[l+d]*u+s[c+d]*h;return a}},Ro=class extends gr{constructor(e,t,n,r){super(e,t,n,r)}interpolate_(e){return this.copySampleValue_(e-1)}},En=class{constructor(e,t,n,r){if(e===void 0)throw new Error("THREE.KeyframeTrack: track name is undefined");if(t===void 0||t.length===0)throw new Error("THREE.KeyframeTrack: no keyframes in track named "+e);this.name=e,this.times=js(t,this.TimeBufferType),this.values=js(n,this.ValueBufferType),this.setInterpolation(r||this.DefaultInterpolation)}static toJSON(e){let t=e.constructor,n;if(t.toJSON!==this.toJSON)n=t.toJSON(e);else{n={name:e.name,times:js(e.times,Array),values:js(e.values,Array)};let r=e.getInterpolation();r!==e.DefaultInterpolation&&(n.interpolation=r)}return n.type=e.ValueTypeName,n}InterpolantFactoryMethodDiscrete(e){return new Ro(this.times,this.values,this.getValueSize(),e)}InterpolantFactoryMethodLinear(e){return new Ao(this.times,this.values,this.getValueSize(),e)}InterpolantFactoryMethodSmooth(e){return new wo(this.times,this.values,this.getValueSize(),e)}setInterpolation(e){let t;switch(e){case Na:t=this.InterpolantFactoryMethodDiscrete;break;case Zs:t=this.InterpolantFactoryMethodLinear;break;case qs:t=this.InterpolantFactoryMethodSmooth}if(t===void 0){let n="unsupported interpolation for "+this.ValueTypeName+" keyframe track named "+this.name;if(this.createInterpolant===void 0){if(e===this.DefaultInterpolation)throw new Error(n);this.setInterpolation(this.DefaultInterpolation)}return console.warn("THREE.KeyframeTrack:",n),this}return this.createInterpolant=t,this}getInterpolation(){switch(this.createInterpolant){case this.InterpolantFactoryMethodDiscrete:return Na;case this.InterpolantFactoryMethodLinear:return Zs;case this.InterpolantFactoryMethodSmooth:return qs}}getValueSize(){return this.values.length/this.times.length}shift(e){if(e!==0){let t=this.times;for(let n=0,r=t.length;n!==r;++n)t[n]+=e}return this}scale(e){if(e!==1){let t=this.times;for(let n=0,r=t.length;n!==r;++n)t[n]*=e}return this}trim(e,t){let n=this.times,r=n.length,a=0,s=r-1;for(;a!==r&&n[a]<e;)++a;for(;s!==-1&&n[s]>t;)--s;if(++s,a!==0||s!==r){a>=s&&(s=Math.max(s,1),a=s-1);let o=this.getValueSize();this.times=n.slice(a,s),this.values=this.values.slice(a*o,s*o)}return this}validate(){let e=!0,t=this.getValueSize();t-Math.floor(t)!==0&&(console.error("THREE.KeyframeTrack: Invalid value size in track.",this),e=!1);let n=this.times,r=this.values,a=n.length;a===0&&(console.error("THREE.KeyframeTrack: Track is empty.",this),e=!1);let s=null;for(let o=0;o!==a;o++){let c=n[o];if(typeof c=="number"&&isNaN(c)){console.error("THREE.KeyframeTrack: Time is not a valid number.",this,o,c),e=!1;break}if(s!==null&&s>c){console.error("THREE.KeyframeTrack: Out of order keys.",this,o,c,s),e=!1;break}s=c}if(r!==void 0&&zp(r))for(let o=0,c=r.length;o!==c;++o){let l=r[o];if(isNaN(l)){console.error("THREE.KeyframeTrack: Value is not a valid number.",this,o,l),e=!1;break}}return e}optimize(){let e=this.times.slice(),t=this.values.slice(),n=this.getValueSize(),r=this.getInterpolation()===qs,a=e.length-1,s=1;for(let o=1;o<a;++o){let c=!1,l=e[o];if(l!==e[o+1]&&(o!==1||l!==e[0]))if(r)c=!0;else{let h=o*n,u=h-n,d=h+n;for(let p=0;p!==n;++p){let m=t[h+p];if(m!==t[u+p]||m!==t[d+p]){c=!0;break}}}if(c){if(o!==s){e[s]=e[o];let h=o*n,u=s*n;for(let d=0;d!==n;++d)t[u+d]=t[h+d]}++s}}if(a>0){e[s]=e[a];for(let o=a*n,c=s*n,l=0;l!==n;++l)t[c+l]=t[o+l];++s}return s!==e.length?(this.times=e.slice(0,s),this.values=t.slice(0,s*n)):(this.times=e,this.values=t),this}clone(){let e=this.times.slice(),t=this.values.slice(),n=new this.constructor(this.name,e,t);return n.createInterpolant=this.createInterpolant,n}};En.prototype.ValueTypeName="",En.prototype.TimeBufferType=Float32Array,En.prototype.ValueBufferType=Float32Array,En.prototype.DefaultInterpolation=Zs;var Vi=class extends En{constructor(e,t,n){super(e,t,n)}};Vi.prototype.ValueTypeName="bool",Vi.prototype.ValueBufferType=Array,Vi.prototype.DefaultInterpolation=Na,Vi.prototype.InterpolantFactoryMethodLinear=void 0,Vi.prototype.InterpolantFactoryMethodSmooth=void 0;var Co=class extends En{constructor(e,t,n,r){super(e,t,n,r)}};Co.prototype.ValueTypeName="color";var Po=class extends En{constructor(e,t,n,r){super(e,t,n,r)}};Po.prototype.ValueTypeName="number";var Io=class extends gr{constructor(e,t,n,r){super(e,t,n,r)}interpolate_(e,t,n,r){let a=this.resultBuffer,s=this.sampleValues,o=this.valueSize,c=(n-t)/(r-t),l=e*o;for(let h=l+o;l!==h;l+=4)kt.slerpFlat(a,0,s,l-o,s,l,c);return a}},is=class extends En{constructor(e,t,n,r){super(e,t,n,r)}InterpolantFactoryMethodLinear(e){return new Io(this.times,this.values,this.getValueSize(),e)}};is.prototype.ValueTypeName="quaternion",is.prototype.InterpolantFactoryMethodSmooth=void 0;var Wi=class extends En{constructor(e,t,n){super(e,t,n)}};Wi.prototype.ValueTypeName="string",Wi.prototype.ValueBufferType=Array,Wi.prototype.DefaultInterpolation=Na,Wi.prototype.InterpolantFactoryMethodLinear=void 0,Wi.prototype.InterpolantFactoryMethodSmooth=void 0;var Lo=class extends En{constructor(e,t,n,r){super(e,t,n,r)}};Lo.prototype.ValueTypeName="vector";var Do=class{constructor(e,t,n){let r=this,a,s=!1,o=0,c=0,l=[];this.onStart=void 0,this.onLoad=e,this.onProgress=t,this.onError=n,this.abortController=new AbortController,this.itemStart=function(h){c++,s===!1&&r.onStart!==void 0&&r.onStart(h,o,c),s=!0},this.itemEnd=function(h){o++,r.onProgress!==void 0&&r.onProgress(h,o,c),o===c&&(s=!1,r.onLoad!==void 0&&r.onLoad())},this.itemError=function(h){r.onError!==void 0&&r.onError(h)},this.resolveURL=function(h){return a?a(h):h},this.setURLModifier=function(h){return a=h,this},this.addHandler=function(h,u){return l.push(h,u),this},this.removeHandler=function(h){let u=l.indexOf(h);return u!==-1&&l.splice(u,2),this},this.getHandler=function(h){for(let u=0,d=l.length;u<d;u+=2){let p=l[u],m=l[u+1];if(p.global&&(p.lastIndex=0),p.test(h))return m}return null},this.abort=function(){return this.abortController.abort(),this.abortController=new AbortController,this}}},hd=new Do,Uo=class{constructor(e){this.manager=e!==void 0?e:hd,this.crossOrigin="anonymous",this.withCredentials=!1,this.path="",this.resourcePath="",this.requestHeader={}}load(){}loadAsync(e,t){let n=this;return new Promise(function(r,a){n.load(e,r,t,a)})}parse(){}setCrossOrigin(e){return this.crossOrigin=e,this}setWithCredentials(e){return this.withCredentials=e,this}setPath(e){return this.path=e,this}setResourcePath(e){return this.resourcePath=e,this}setRequestHeader(e){return this.requestHeader=e,this}abort(){return this}};Uo.DEFAULT_MATERIAL_NAME="__DEFAULT";var rs=class extends Kt{constructor(e,t=1){super(),this.isLight=!0,this.type="Light",this.color=new Ve(e),this.intensity=t}dispose(){}copy(e,t){return super.copy(e,t),this.color.copy(e.color),this.intensity=e.intensity,this}toJSON(e){let t=super.toJSON(e);return t.object.color=this.color.getHex(),t.object.intensity=this.intensity,this.groundColor!==void 0&&(t.object.groundColor=this.groundColor.getHex()),this.distance!==void 0&&(t.object.distance=this.distance),this.angle!==void 0&&(t.object.angle=this.angle),this.decay!==void 0&&(t.object.decay=this.decay),this.penumbra!==void 0&&(t.object.penumbra=this.penumbra),this.shadow!==void 0&&(t.object.shadow=this.shadow.toJSON()),this.target!==void 0&&(t.object.target=this.target.uuid),t}},as=class extends rs{constructor(e,t,n){super(e,n),this.isHemisphereLight=!0,this.type="HemisphereLight",this.position.copy(Kt.DEFAULT_UP),this.updateMatrix(),this.groundColor=new Ve(t)}copy(e,t){return super.copy(e,t),this.groundColor.copy(e.groundColor),this}},jl=new qe,cu=new E,hu=new E,rc=class{constructor(e){this.camera=e,this.intensity=1,this.bias=0,this.normalBias=0,this.radius=1,this.blurSamples=8,this.mapSize=new pe(512,512),this.mapType=ci,this.map=null,this.mapPass=null,this.matrix=new qe,this.autoUpdate=!0,this.needsUpdate=!1,this._frustum=new qi,this._frameExtents=new pe(1,1),this._viewportCount=1,this._viewports=[new xt(0,0,1,1)]}getViewportCount(){return this._viewportCount}getFrustum(){return this._frustum}updateMatrices(e){let t=this.camera,n=this.matrix;cu.setFromMatrixPosition(e.matrixWorld),t.position.copy(cu),hu.setFromMatrixPosition(e.target.matrixWorld),t.lookAt(hu),t.updateMatrixWorld(),jl.multiplyMatrices(t.projectionMatrix,t.matrixWorldInverse),this._frustum.setFromProjectionMatrix(jl,t.coordinateSystem,t.reversedDepth),t.reversedDepth?n.set(.5,0,0,.5,0,.5,0,.5,0,0,1,0,0,0,0,1):n.set(.5,0,0,.5,0,.5,0,.5,0,0,.5,.5,0,0,0,1),n.multiply(jl)}getViewport(e){return this._viewports[e]}getFrameExtents(){return this._frameExtents}dispose(){this.map&&this.map.dispose(),this.mapPass&&this.mapPass.dispose()}copy(e){return this.camera=e.camera.clone(),this.intensity=e.intensity,this.bias=e.bias,this.radius=e.radius,this.autoUpdate=e.autoUpdate,this.needsUpdate=e.needsUpdate,this.normalBias=e.normalBias,this.blurSamples=e.blurSamples,this.mapSize.copy(e.mapSize),this}clone(){return new this.constructor().copy(this)}toJSON(){let e={};return this.intensity!==1&&(e.intensity=this.intensity),this.bias!==0&&(e.bias=this.bias),this.normalBias!==0&&(e.normalBias=this.normalBias),this.radius!==1&&(e.radius=this.radius),this.mapSize.x===512&&this.mapSize.y===512||(e.mapSize=this.mapSize.toArray()),e.camera=this.camera.toJSON(!1).object,delete e.camera.matrix,e}};var k0=new qe,z0=new E,H0=new E;var vr=class extends na{constructor(e=-1,t=1,n=1,r=-1,a=.1,s=2e3){super(),this.isOrthographicCamera=!0,this.type="OrthographicCamera",this.zoom=1,this.view=null,this.left=e,this.right=t,this.top=n,this.bottom=r,this.near=a,this.far=s,this.updateProjectionMatrix()}copy(e,t){return super.copy(e,t),this.left=e.left,this.right=e.right,this.top=e.top,this.bottom=e.bottom,this.near=e.near,this.far=e.far,this.zoom=e.zoom,this.view=e.view===null?null:Object.assign({},e.view),this}setViewOffset(e,t,n,r,a,s){this.view===null&&(this.view={enabled:!0,fullWidth:1,fullHeight:1,offsetX:0,offsetY:0,width:1,height:1}),this.view.enabled=!0,this.view.fullWidth=e,this.view.fullHeight=t,this.view.offsetX=n,this.view.offsetY=r,this.view.width=a,this.view.height=s,this.updateProjectionMatrix()}clearViewOffset(){this.view!==null&&(this.view.enabled=!1),this.updateProjectionMatrix()}updateProjectionMatrix(){let e=(this.right-this.left)/(2*this.zoom),t=(this.top-this.bottom)/(2*this.zoom),n=(this.right+this.left)/2,r=(this.top+this.bottom)/2,a=n-e,s=n+e,o=r+t,c=r-t;if(this.view!==null&&this.view.enabled){let l=(this.right-this.left)/this.view.fullWidth/this.zoom,h=(this.top-this.bottom)/this.view.fullHeight/this.zoom;a+=l*this.view.offsetX,s=a+l*this.view.width,o-=h*this.view.offsetY,c=o-h*this.view.height}this.projectionMatrix.makeOrthographic(a,s,o,c,this.near,this.far,this.coordinateSystem,this.reversedDepth),this.projectionMatrixInverse.copy(this.projectionMatrix).invert()}toJSON(e){let t=super.toJSON(e);return t.object.zoom=this.zoom,t.object.left=this.left,t.object.right=this.right,t.object.top=this.top,t.object.bottom=this.bottom,t.object.near=this.near,t.object.far=this.far,this.view!==null&&(t.object.view=Object.assign({},this.view)),t}},ac=class extends rc{constructor(){super(new vr(-5,5,5,-5,.5,500)),this.isDirectionalLightShadow=!0}},sa=class extends rs{constructor(e,t){super(e,t),this.isDirectionalLight=!0,this.type="DirectionalLight",this.position.copy(Kt.DEFAULT_UP),this.updateMatrix(),this.target=new Kt,this.shadow=new ac}dispose(){this.shadow.dispose()}copy(e){return super.copy(e),this.target=e.target.clone(),this.shadow=e.shadow.clone(),this}};var G0=new qe,V0=new qe,W0=new qe;var No=class extends rn{constructor(e=[]){super(),this.isArrayCamera=!0,this.isMultiViewCamera=!1,this.cameras=e}};var X0=new E,j0=new kt,q0=new E,Y0=new E,Z0=new E;var J0=new E,K0=new kt,$0=new E,Q0=new E;var Kc="\\[\\]\\.:\\/",Hp=new RegExp("["+Kc+"]","g"),ql="[^"+Kc+"]",Gp="[^"+Kc.replace("\\.","")+"]",Vp=new RegExp("^"+/((?:WC+[\/:])*)/.source.replace("WC",ql)+/(WCOD+)?/.source.replace("WCOD",Gp)+/(?:\.(WC+)(?:\[(.+)\])?)?/.source.replace("WC",ql)+/\.(WC+)(?:\[(.+)\])?/.source.replace("WC",ql)+"$"),Wp=["material","materials","bones","map"],yt=class i{constructor(e,t,n){this.path=t,this.parsedPath=n||i.parseTrackName(t),this.node=i.findNode(e,this.parsedPath.nodeName),this.rootNode=e,this.getValue=this._getValue_unbound,this.setValue=this._setValue_unbound}static create(e,t,n){return e&&e.isAnimationObjectGroup?new i.Composite(e,t,n):new i(e,t,n)}static sanitizeNodeName(e){return e.replace(/\s/g,"_").replace(Hp,"")}static parseTrackName(e){let t=Vp.exec(e);if(t===null)throw new Error("PropertyBinding: Cannot parse trackName: "+e);let n={nodeName:t[2],objectName:t[3],objectIndex:t[4],propertyName:t[5],propertyIndex:t[6]},r=n.nodeName&&n.nodeName.lastIndexOf(".");if(r!==void 0&&r!==-1){let a=n.nodeName.substring(r+1);Wp.indexOf(a)!==-1&&(n.nodeName=n.nodeName.substring(0,r),n.objectName=a)}if(n.propertyName===null||n.propertyName.length===0)throw new Error("PropertyBinding: can not parse propertyName from trackName: "+e);return n}static findNode(e,t){if(t===void 0||t===""||t==="."||t===-1||t===e.name||t===e.uuid)return e;if(e.skeleton){let n=e.skeleton.getBoneByName(t);if(n!==void 0)return n}if(e.children){let n=function(a){for(let s=0;s<a.length;s++){let o=a[s];if(o.name===t||o.uuid===t)return o;let c=n(o.children);if(c)return c}return null},r=n(e.children);if(r)return r}return null}_getValue_unavailable(){}_setValue_unavailable(){}_getValue_direct(e,t){e[t]=this.targetObject[this.propertyName]}_getValue_array(e,t){let n=this.resolvedProperty;for(let r=0,a=n.length;r!==a;++r)e[t++]=n[r]}_getValue_arrayElement(e,t){e[t]=this.resolvedProperty[this.propertyIndex]}_getValue_toArray(e,t){this.resolvedProperty.toArray(e,t)}_setValue_direct(e,t){this.targetObject[this.propertyName]=e[t]}_setValue_direct_setNeedsUpdate(e,t){this.targetObject[this.propertyName]=e[t],this.targetObject.needsUpdate=!0}_setValue_direct_setMatrixWorldNeedsUpdate(e,t){this.targetObject[this.propertyName]=e[t],this.targetObject.matrixWorldNeedsUpdate=!0}_setValue_array(e,t){let n=this.resolvedProperty;for(let r=0,a=n.length;r!==a;++r)n[r]=e[t++]}_setValue_array_setNeedsUpdate(e,t){let n=this.resolvedProperty;for(let r=0,a=n.length;r!==a;++r)n[r]=e[t++];this.targetObject.needsUpdate=!0}_setValue_array_setMatrixWorldNeedsUpdate(e,t){let n=this.resolvedProperty;for(let r=0,a=n.length;r!==a;++r)n[r]=e[t++];this.targetObject.matrixWorldNeedsUpdate=!0}_setValue_arrayElement(e,t){this.resolvedProperty[this.propertyIndex]=e[t]}_setValue_arrayElement_setNeedsUpdate(e,t){this.resolvedProperty[this.propertyIndex]=e[t],this.targetObject.needsUpdate=!0}_setValue_arrayElement_setMatrixWorldNeedsUpdate(e,t){this.resolvedProperty[this.propertyIndex]=e[t],this.targetObject.matrixWorldNeedsUpdate=!0}_setValue_fromArray(e,t){this.resolvedProperty.fromArray(e,t)}_setValue_fromArray_setNeedsUpdate(e,t){this.resolvedProperty.fromArray(e,t),this.targetObject.needsUpdate=!0}_setValue_fromArray_setMatrixWorldNeedsUpdate(e,t){this.resolvedProperty.fromArray(e,t),this.targetObject.matrixWorldNeedsUpdate=!0}_getValue_unbound(e,t){this.bind(),this.getValue(e,t)}_setValue_unbound(e,t){this.bind(),this.setValue(e,t)}bind(){let e=this.node,t=this.parsedPath,n=t.objectName,r=t.propertyName,a=t.propertyIndex;if(e||(e=i.findNode(this.rootNode,t.nodeName),this.node=e),this.getValue=this._getValue_unavailable,this.setValue=this._setValue_unavailable,!e)return void console.warn("THREE.PropertyBinding: No target node found for track: "+this.path+".");if(n){let l=t.objectIndex;switch(n){case"materials":if(!e.material)return void console.error("THREE.PropertyBinding: Can not bind to material as node does not have a material.",this);if(!e.material.materials)return void console.error("THREE.PropertyBinding: Can not bind to material.materials as node.material does not have a materials array.",this);e=e.material.materials;break;case"bones":if(!e.skeleton)return void console.error("THREE.PropertyBinding: Can not bind to bones as node does not have a skeleton.",this);e=e.skeleton.bones;for(let h=0;h<e.length;h++)if(e[h].name===l){l=h;break}break;case"map":if("map"in e){e=e.map;break}if(!e.material)return void console.error("THREE.PropertyBinding: Can not bind to material as node does not have a material.",this);if(!e.material.map)return void console.error("THREE.PropertyBinding: Can not bind to material.map as node.material does not have a map.",this);e=e.material.map;break;default:if(e[n]===void 0)return void console.error("THREE.PropertyBinding: Can not bind to objectName of node undefined.",this);e=e[n]}if(l!==void 0){if(e[l]===void 0)return void console.error("THREE.PropertyBinding: Trying to bind to objectIndex of objectName, but is undefined.",this,e);e=e[l]}}let s=e[r];if(s===void 0){let l=t.nodeName;return void console.error("THREE.PropertyBinding: Trying to update property for track: "+l+"."+r+" but it wasn't found.",e)}let o=this.Versioning.None;this.targetObject=e,e.isMaterial===!0?o=this.Versioning.NeedsUpdate:e.isObject3D===!0&&(o=this.Versioning.MatrixWorldNeedsUpdate);let c=this.BindingType.Direct;if(a!==void 0){if(r==="morphTargetInfluences"){if(!e.geometry)return void console.error("THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.",this);if(!e.geometry.morphAttributes)return void console.error("THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.morphAttributes.",this);e.morphTargetDictionary[a]!==void 0&&(a=e.morphTargetDictionary[a])}c=this.BindingType.ArrayElement,this.resolvedProperty=s,this.propertyIndex=a}else s.fromArray!==void 0&&s.toArray!==void 0?(c=this.BindingType.HasFromToArray,this.resolvedProperty=s):Array.isArray(s)?(c=this.BindingType.EntireArray,this.resolvedProperty=s):this.propertyName=r;this.getValue=this.GetterByBindingType[c],this.setValue=this.SetterByBindingTypeAndVersioning[c][o]}unbind(){this.node=null,this.getValue=this._getValue_unbound,this.setValue=this._setValue_unbound}};yt.Composite=class{constructor(i,e,t){let n=t||yt.parseTrackName(e);this._targetGroup=i,this._bindings=i.subscribe_(e,n)}getValue(i,e){this.bind();let t=this._targetGroup.nCachedObjects_,n=this._bindings[t];n!==void 0&&n.getValue(i,e)}setValue(i,e){let t=this._bindings;for(let n=this._targetGroup.nCachedObjects_,r=t.length;n!==r;++n)t[n].setValue(i,e)}bind(){let i=this._bindings;for(let e=this._targetGroup.nCachedObjects_,t=i.length;e!==t;++e)i[e].bind()}unbind(){let i=this._bindings;for(let e=this._targetGroup.nCachedObjects_,t=i.length;e!==t;++e)i[e].unbind()}},yt.prototype.BindingType={Direct:0,EntireArray:1,ArrayElement:2,HasFromToArray:3},yt.prototype.Versioning={None:0,NeedsUpdate:1,MatrixWorldNeedsUpdate:2},yt.prototype.GetterByBindingType=[yt.prototype._getValue_direct,yt.prototype._getValue_array,yt.prototype._getValue_arrayElement,yt.prototype._getValue_toArray],yt.prototype.SetterByBindingTypeAndVersioning=[[yt.prototype._setValue_direct,yt.prototype._setValue_direct_setNeedsUpdate,yt.prototype._setValue_direct_setMatrixWorldNeedsUpdate],[yt.prototype._setValue_array,yt.prototype._setValue_array_setNeedsUpdate,yt.prototype._setValue_array_setMatrixWorldNeedsUpdate],[yt.prototype._setValue_arrayElement,yt.prototype._setValue_arrayElement_setNeedsUpdate,yt.prototype._setValue_arrayElement_setMatrixWorldNeedsUpdate],[yt.prototype._setValue_fromArray,yt.prototype._setValue_fromArray_setNeedsUpdate,yt.prototype._setValue_fromArray_setMatrixWorldNeedsUpdate]];var eg=new Float32Array(1);var tg=new qe;var ng=new pe;var ig=new E,rg=new E,ag=new E,sg=new E,og=new E,lg=new E,cg=new E;var hg=new E;var ug=new E,dg=new qe,pg=new qe;var fg=new E,mg=new Ve,gg=new Ve;var vg=new E,_g=new E,yg=new E;var xg=new E,Mg=new na;var Sg=new Nn;var bg=new E;function $c(i,e,t,n){let r=(function(a){switch(a){case ci:case uc:return{byteLength:1,components:1};case ca:case dc:case ha:return{byteLength:2,components:1};case Yo:case Zo:return{byteLength:2,components:4};case Mr:case qo:case jn:return{byteLength:4,components:1};case pc:case fc:return{byteLength:4,components:3}}throw new Error(`Unknown texture type ${a}.`)})(n);switch(t){case 1021:return i*e;case Jo:case Ko:return i*e/r.components*r.byteLength;case 1030:case 1031:return i*e*2/r.components*r.byteLength;case 1022:return i*e*3/r.components*r.byteLength;case qn:case 1033:return i*e*4/r.components*r.byteLength;case 33776:case 33777:return Math.floor((i+3)/4)*Math.floor((e+3)/4)*8;case 33778:case 33779:return Math.floor((i+3)/4)*Math.floor((e+3)/4)*16;case 35841:case 35843:return Math.max(i,16)*Math.max(e,8)/4;case 35840:case 35842:return Math.max(i,8)*Math.max(e,8)/2;case 36196:case 37492:return Math.floor((i+3)/4)*Math.floor((e+3)/4)*8;case 37496:case 37808:return Math.floor((i+3)/4)*Math.floor((e+3)/4)*16;case 37809:return Math.floor((i+4)/5)*Math.floor((e+3)/4)*16;case 37810:return Math.floor((i+4)/5)*Math.floor((e+4)/5)*16;case 37811:return Math.floor((i+5)/6)*Math.floor((e+4)/5)*16;case 37812:return Math.floor((i+5)/6)*Math.floor((e+5)/6)*16;case 37813:return Math.floor((i+7)/8)*Math.floor((e+4)/5)*16;case 37814:return Math.floor((i+7)/8)*Math.floor((e+5)/6)*16;case 37815:return Math.floor((i+7)/8)*Math.floor((e+7)/8)*16;case 37816:return Math.floor((i+9)/10)*Math.floor((e+4)/5)*16;case 37817:return Math.floor((i+9)/10)*Math.floor((e+5)/6)*16;case 37818:return Math.floor((i+9)/10)*Math.floor((e+7)/8)*16;case 37819:return Math.floor((i+9)/10)*Math.floor((e+9)/10)*16;case 37820:return Math.floor((i+11)/12)*Math.floor((e+9)/10)*16;case 37821:return Math.floor((i+11)/12)*Math.floor((e+11)/12)*16;case 36492:case 36494:case 36495:return Math.ceil(i/4)*Math.ceil(e/4)*16;case 36283:case 36284:return Math.ceil(i/4)*Math.ceil(e/4)*8;case 36285:case 36286:return Math.ceil(i/4)*Math.ceil(e/4)*16}throw new Error(`Unable to determine texture byte length for ${t} format.`)}typeof __THREE_DEVTOOLS__!="undefined"&&__THREE_DEVTOOLS__.dispatchEvent(new CustomEvent("register",{detail:{revision:"180"}})),typeof window!="undefined"&&(window.__THREE__?console.warn("WARNING: Multiple instances of Three.js being imported."):window.__THREE__="180");/**
 * @license
 * Copyright 2010-2025 Three.js Authors
 * SPDX-License-Identifier: MIT
 */function Ud(){let i=null,e=!1,t=null,n=null;function r(a,s){t(a,s),n=i.requestAnimationFrame(r)}return{start:function(){e!==!0&&t!==null&&(n=i.requestAnimationFrame(r),e=!0)},stop:function(){i.cancelAnimationFrame(n),e=!1},setAnimationLoop:function(a){t=a},setContext:function(a){i=a}}}function jp(i){let e=new WeakMap;return{get:function(t){return t.isInterleavedBufferAttribute&&(t=t.data),e.get(t)},remove:function(t){t.isInterleavedBufferAttribute&&(t=t.data);let n=e.get(t);n&&(i.deleteBuffer(n.buffer),e.delete(t))},update:function(t,n){if(t.isInterleavedBufferAttribute&&(t=t.data),t.isGLBufferAttribute){let a=e.get(t);return void((!a||a.version<t.version)&&e.set(t,{buffer:t.buffer,type:t.type,bytesPerElement:t.elementSize,version:t.version}))}let r=e.get(t);if(r===void 0)e.set(t,(function(a,s){let o=a.array,c=a.usage,l=o.byteLength,h=i.createBuffer(),u;if(i.bindBuffer(s,h),i.bufferData(s,o,c),a.onUploadCallback(),o instanceof Float32Array)u=i.FLOAT;else if(typeof Float16Array!="undefined"&&o instanceof Float16Array)u=i.HALF_FLOAT;else if(o instanceof Uint16Array)u=a.isFloat16BufferAttribute?i.HALF_FLOAT:i.UNSIGNED_SHORT;else if(o instanceof Int16Array)u=i.SHORT;else if(o instanceof Uint32Array)u=i.UNSIGNED_INT;else if(o instanceof Int32Array)u=i.INT;else if(o instanceof Int8Array)u=i.BYTE;else if(o instanceof Uint8Array)u=i.UNSIGNED_BYTE;else{if(!(o instanceof Uint8ClampedArray))throw new Error("THREE.WebGLAttributes: Unsupported buffer data format: "+o);u=i.UNSIGNED_BYTE}return{buffer:h,type:u,bytesPerElement:o.BYTES_PER_ELEMENT,version:a.version,size:l}})(t,n));else if(r.version<t.version){if(r.size!==t.array.byteLength)throw new Error("THREE.WebGLAttributes: The size of the buffer attribute's array buffer does not match the original size. Resizing buffer attributes is not supported.");(function(a,s,o){let c=s.array,l=s.updateRanges;if(i.bindBuffer(o,a),l.length===0)i.bufferSubData(o,0,c);else{l.sort((u,d)=>u.start-d.start);let h=0;for(let u=1;u<l.length;u++){let d=l[h],p=l[u];p.start<=d.start+d.count+1?d.count=Math.max(d.count,p.start+p.count-d.start):(++h,l[h]=p)}l.length=h+1;for(let u=0,d=l.length;u<d;u++){let p=l[u];i.bufferSubData(o,p.start*c.BYTES_PER_ELEMENT,c,p.start,p.count)}s.clearUpdateRanges()}s.onUploadCallback()})(r.buffer,t,n),r.version=t.version}}}}var rt={alphahash_fragment:`#ifdef USE_ALPHAHASH
	if ( diffuseColor.a < getAlphaHashThreshold( vPosition ) ) discard;
#endif`,alphahash_pars_fragment:`#ifdef USE_ALPHAHASH
	const float ALPHA_HASH_SCALE = 0.05;
	float hash2D( vec2 value ) {
		return fract( 1.0e4 * sin( 17.0 * value.x + 0.1 * value.y ) * ( 0.1 + abs( sin( 13.0 * value.y + value.x ) ) ) );
	}
	float hash3D( vec3 value ) {
		return hash2D( vec2( hash2D( value.xy ), value.z ) );
	}
	float getAlphaHashThreshold( vec3 position ) {
		float maxDeriv = max(
			length( dFdx( position.xyz ) ),
			length( dFdy( position.xyz ) )
		);
		float pixScale = 1.0 / ( ALPHA_HASH_SCALE * maxDeriv );
		vec2 pixScales = vec2(
			exp2( floor( log2( pixScale ) ) ),
			exp2( ceil( log2( pixScale ) ) )
		);
		vec2 alpha = vec2(
			hash3D( floor( pixScales.x * position.xyz ) ),
			hash3D( floor( pixScales.y * position.xyz ) )
		);
		float lerpFactor = fract( log2( pixScale ) );
		float x = ( 1.0 - lerpFactor ) * alpha.x + lerpFactor * alpha.y;
		float a = min( lerpFactor, 1.0 - lerpFactor );
		vec3 cases = vec3(
			x * x / ( 2.0 * a * ( 1.0 - a ) ),
			( x - 0.5 * a ) / ( 1.0 - a ),
			1.0 - ( ( 1.0 - x ) * ( 1.0 - x ) / ( 2.0 * a * ( 1.0 - a ) ) )
		);
		float threshold = ( x < ( 1.0 - a ) )
			? ( ( x < a ) ? cases.x : cases.y )
			: cases.z;
		return clamp( threshold , 1.0e-6, 1.0 );
	}
#endif`,alphamap_fragment:`#ifdef USE_ALPHAMAP
	diffuseColor.a *= texture2D( alphaMap, vAlphaMapUv ).g;
#endif`,alphamap_pars_fragment:`#ifdef USE_ALPHAMAP
	uniform sampler2D alphaMap;
#endif`,alphatest_fragment:`#ifdef USE_ALPHATEST
	#ifdef ALPHA_TO_COVERAGE
	diffuseColor.a = smoothstep( alphaTest, alphaTest + fwidth( diffuseColor.a ), diffuseColor.a );
	if ( diffuseColor.a == 0.0 ) discard;
	#else
	if ( diffuseColor.a < alphaTest ) discard;
	#endif
#endif`,alphatest_pars_fragment:`#ifdef USE_ALPHATEST
	uniform float alphaTest;
#endif`,aomap_fragment:`#ifdef USE_AOMAP
	float ambientOcclusion = ( texture2D( aoMap, vAoMapUv ).r - 1.0 ) * aoMapIntensity + 1.0;
	reflectedLight.indirectDiffuse *= ambientOcclusion;
	#if defined( USE_CLEARCOAT ) 
		clearcoatSpecularIndirect *= ambientOcclusion;
	#endif
	#if defined( USE_SHEEN ) 
		sheenSpecularIndirect *= ambientOcclusion;
	#endif
	#if defined( USE_ENVMAP ) && defined( STANDARD )
		float dotNV = saturate( dot( geometryNormal, geometryViewDir ) );
		reflectedLight.indirectSpecular *= computeSpecularOcclusion( dotNV, ambientOcclusion, material.roughness );
	#endif
#endif`,aomap_pars_fragment:`#ifdef USE_AOMAP
	uniform sampler2D aoMap;
	uniform float aoMapIntensity;
#endif`,batching_pars_vertex:`#ifdef USE_BATCHING
	#if ! defined( GL_ANGLE_multi_draw )
	#define gl_DrawID _gl_DrawID
	uniform int _gl_DrawID;
	#endif
	uniform highp sampler2D batchingTexture;
	uniform highp usampler2D batchingIdTexture;
	mat4 getBatchingMatrix( const in float i ) {
		int size = textureSize( batchingTexture, 0 ).x;
		int j = int( i ) * 4;
		int x = j % size;
		int y = j / size;
		vec4 v1 = texelFetch( batchingTexture, ivec2( x, y ), 0 );
		vec4 v2 = texelFetch( batchingTexture, ivec2( x + 1, y ), 0 );
		vec4 v3 = texelFetch( batchingTexture, ivec2( x + 2, y ), 0 );
		vec4 v4 = texelFetch( batchingTexture, ivec2( x + 3, y ), 0 );
		return mat4( v1, v2, v3, v4 );
	}
	float getIndirectIndex( const in int i ) {
		int size = textureSize( batchingIdTexture, 0 ).x;
		int x = i % size;
		int y = i / size;
		return float( texelFetch( batchingIdTexture, ivec2( x, y ), 0 ).r );
	}
#endif
#ifdef USE_BATCHING_COLOR
	uniform sampler2D batchingColorTexture;
	vec3 getBatchingColor( const in float i ) {
		int size = textureSize( batchingColorTexture, 0 ).x;
		int j = int( i );
		int x = j % size;
		int y = j / size;
		return texelFetch( batchingColorTexture, ivec2( x, y ), 0 ).rgb;
	}
#endif`,batching_vertex:`#ifdef USE_BATCHING
	mat4 batchingMatrix = getBatchingMatrix( getIndirectIndex( gl_DrawID ) );
#endif`,begin_vertex:`vec3 transformed = vec3( position );
#ifdef USE_ALPHAHASH
	vPosition = vec3( position );
#endif`,beginnormal_vertex:`vec3 objectNormal = vec3( normal );
#ifdef USE_TANGENT
	vec3 objectTangent = vec3( tangent.xyz );
#endif`,bsdfs:`float G_BlinnPhong_Implicit( ) {
	return 0.25;
}
float D_BlinnPhong( const in float shininess, const in float dotNH ) {
	return RECIPROCAL_PI * ( shininess * 0.5 + 1.0 ) * pow( dotNH, shininess );
}
vec3 BRDF_BlinnPhong( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, const in vec3 specularColor, const in float shininess ) {
	vec3 halfDir = normalize( lightDir + viewDir );
	float dotNH = saturate( dot( normal, halfDir ) );
	float dotVH = saturate( dot( viewDir, halfDir ) );
	vec3 F = F_Schlick( specularColor, 1.0, dotVH );
	float G = G_BlinnPhong_Implicit( );
	float D = D_BlinnPhong( shininess, dotNH );
	return F * ( G * D );
} // validated`,iridescence_fragment:`#ifdef USE_IRIDESCENCE
	const mat3 XYZ_TO_REC709 = mat3(
		 3.2404542, -0.9692660,  0.0556434,
		-1.5371385,  1.8760108, -0.2040259,
		-0.4985314,  0.0415560,  1.0572252
	);
	vec3 Fresnel0ToIor( vec3 fresnel0 ) {
		vec3 sqrtF0 = sqrt( fresnel0 );
		return ( vec3( 1.0 ) + sqrtF0 ) / ( vec3( 1.0 ) - sqrtF0 );
	}
	vec3 IorToFresnel0( vec3 transmittedIor, float incidentIor ) {
		return pow2( ( transmittedIor - vec3( incidentIor ) ) / ( transmittedIor + vec3( incidentIor ) ) );
	}
	float IorToFresnel0( float transmittedIor, float incidentIor ) {
		return pow2( ( transmittedIor - incidentIor ) / ( transmittedIor + incidentIor ));
	}
	vec3 evalSensitivity( float OPD, vec3 shift ) {
		float phase = 2.0 * PI * OPD * 1.0e-9;
		vec3 val = vec3( 5.4856e-13, 4.4201e-13, 5.2481e-13 );
		vec3 pos = vec3( 1.6810e+06, 1.7953e+06, 2.2084e+06 );
		vec3 var = vec3( 4.3278e+09, 9.3046e+09, 6.6121e+09 );
		vec3 xyz = val * sqrt( 2.0 * PI * var ) * cos( pos * phase + shift ) * exp( - pow2( phase ) * var );
		xyz.x += 9.7470e-14 * sqrt( 2.0 * PI * 4.5282e+09 ) * cos( 2.2399e+06 * phase + shift[ 0 ] ) * exp( - 4.5282e+09 * pow2( phase ) );
		xyz /= 1.0685e-7;
		vec3 rgb = XYZ_TO_REC709 * xyz;
		return rgb;
	}
	vec3 evalIridescence( float outsideIOR, float eta2, float cosTheta1, float thinFilmThickness, vec3 baseF0 ) {
		vec3 I;
		float iridescenceIOR = mix( outsideIOR, eta2, smoothstep( 0.0, 0.03, thinFilmThickness ) );
		float sinTheta2Sq = pow2( outsideIOR / iridescenceIOR ) * ( 1.0 - pow2( cosTheta1 ) );
		float cosTheta2Sq = 1.0 - sinTheta2Sq;
		if ( cosTheta2Sq < 0.0 ) {
			return vec3( 1.0 );
		}
		float cosTheta2 = sqrt( cosTheta2Sq );
		float R0 = IorToFresnel0( iridescenceIOR, outsideIOR );
		float R12 = F_Schlick( R0, 1.0, cosTheta1 );
		float T121 = 1.0 - R12;
		float phi12 = 0.0;
		if ( iridescenceIOR < outsideIOR ) phi12 = PI;
		float phi21 = PI - phi12;
		vec3 baseIOR = Fresnel0ToIor( clamp( baseF0, 0.0, 0.9999 ) );		vec3 R1 = IorToFresnel0( baseIOR, iridescenceIOR );
		vec3 R23 = F_Schlick( R1, 1.0, cosTheta2 );
		vec3 phi23 = vec3( 0.0 );
		if ( baseIOR[ 0 ] < iridescenceIOR ) phi23[ 0 ] = PI;
		if ( baseIOR[ 1 ] < iridescenceIOR ) phi23[ 1 ] = PI;
		if ( baseIOR[ 2 ] < iridescenceIOR ) phi23[ 2 ] = PI;
		float OPD = 2.0 * iridescenceIOR * thinFilmThickness * cosTheta2;
		vec3 phi = vec3( phi21 ) + phi23;
		vec3 R123 = clamp( R12 * R23, 1e-5, 0.9999 );
		vec3 r123 = sqrt( R123 );
		vec3 Rs = pow2( T121 ) * R23 / ( vec3( 1.0 ) - R123 );
		vec3 C0 = R12 + Rs;
		I = C0;
		vec3 Cm = Rs - T121;
		for ( int m = 1; m <= 2; ++ m ) {
			Cm *= r123;
			vec3 Sm = 2.0 * evalSensitivity( float( m ) * OPD, float( m ) * phi );
			I += Cm * Sm;
		}
		return max( I, vec3( 0.0 ) );
	}
#endif`,bumpmap_pars_fragment:`#ifdef USE_BUMPMAP
	uniform sampler2D bumpMap;
	uniform float bumpScale;
	vec2 dHdxy_fwd() {
		vec2 dSTdx = dFdx( vBumpMapUv );
		vec2 dSTdy = dFdy( vBumpMapUv );
		float Hll = bumpScale * texture2D( bumpMap, vBumpMapUv ).x;
		float dBx = bumpScale * texture2D( bumpMap, vBumpMapUv + dSTdx ).x - Hll;
		float dBy = bumpScale * texture2D( bumpMap, vBumpMapUv + dSTdy ).x - Hll;
		return vec2( dBx, dBy );
	}
	vec3 perturbNormalArb( vec3 surf_pos, vec3 surf_norm, vec2 dHdxy, float faceDirection ) {
		vec3 vSigmaX = normalize( dFdx( surf_pos.xyz ) );
		vec3 vSigmaY = normalize( dFdy( surf_pos.xyz ) );
		vec3 vN = surf_norm;
		vec3 R1 = cross( vSigmaY, vN );
		vec3 R2 = cross( vN, vSigmaX );
		float fDet = dot( vSigmaX, R1 ) * faceDirection;
		vec3 vGrad = sign( fDet ) * ( dHdxy.x * R1 + dHdxy.y * R2 );
		return normalize( abs( fDet ) * surf_norm - vGrad );
	}
#endif`,clipping_planes_fragment:`#if NUM_CLIPPING_PLANES > 0
	vec4 plane;
	#ifdef ALPHA_TO_COVERAGE
		float distanceToPlane, distanceGradient;
		float clipOpacity = 1.0;
		#pragma unroll_loop_start
		for ( int i = 0; i < UNION_CLIPPING_PLANES; i ++ ) {
			plane = clippingPlanes[ i ];
			distanceToPlane = - dot( vClipPosition, plane.xyz ) + plane.w;
			distanceGradient = fwidth( distanceToPlane ) / 2.0;
			clipOpacity *= smoothstep( - distanceGradient, distanceGradient, distanceToPlane );
			if ( clipOpacity == 0.0 ) discard;
		}
		#pragma unroll_loop_end
		#if UNION_CLIPPING_PLANES < NUM_CLIPPING_PLANES
			float unionClipOpacity = 1.0;
			#pragma unroll_loop_start
			for ( int i = UNION_CLIPPING_PLANES; i < NUM_CLIPPING_PLANES; i ++ ) {
				plane = clippingPlanes[ i ];
				distanceToPlane = - dot( vClipPosition, plane.xyz ) + plane.w;
				distanceGradient = fwidth( distanceToPlane ) / 2.0;
				unionClipOpacity *= 1.0 - smoothstep( - distanceGradient, distanceGradient, distanceToPlane );
			}
			#pragma unroll_loop_end
			clipOpacity *= 1.0 - unionClipOpacity;
		#endif
		diffuseColor.a *= clipOpacity;
		if ( diffuseColor.a == 0.0 ) discard;
	#else
		#pragma unroll_loop_start
		for ( int i = 0; i < UNION_CLIPPING_PLANES; i ++ ) {
			plane = clippingPlanes[ i ];
			if ( dot( vClipPosition, plane.xyz ) > plane.w ) discard;
		}
		#pragma unroll_loop_end
		#if UNION_CLIPPING_PLANES < NUM_CLIPPING_PLANES
			bool clipped = true;
			#pragma unroll_loop_start
			for ( int i = UNION_CLIPPING_PLANES; i < NUM_CLIPPING_PLANES; i ++ ) {
				plane = clippingPlanes[ i ];
				clipped = ( dot( vClipPosition, plane.xyz ) > plane.w ) && clipped;
			}
			#pragma unroll_loop_end
			if ( clipped ) discard;
		#endif
	#endif
#endif`,clipping_planes_pars_fragment:`#if NUM_CLIPPING_PLANES > 0
	varying vec3 vClipPosition;
	uniform vec4 clippingPlanes[ NUM_CLIPPING_PLANES ];
#endif`,clipping_planes_pars_vertex:`#if NUM_CLIPPING_PLANES > 0
	varying vec3 vClipPosition;
#endif`,clipping_planes_vertex:`#if NUM_CLIPPING_PLANES > 0
	vClipPosition = - mvPosition.xyz;
#endif`,color_fragment:`#if defined( USE_COLOR_ALPHA )
	diffuseColor *= vColor;
#elif defined( USE_COLOR )
	diffuseColor.rgb *= vColor;
#endif`,color_pars_fragment:`#if defined( USE_COLOR_ALPHA )
	varying vec4 vColor;
#elif defined( USE_COLOR )
	varying vec3 vColor;
#endif`,color_pars_vertex:`#if defined( USE_COLOR_ALPHA )
	varying vec4 vColor;
#elif defined( USE_COLOR ) || defined( USE_INSTANCING_COLOR ) || defined( USE_BATCHING_COLOR )
	varying vec3 vColor;
#endif`,color_vertex:`#if defined( USE_COLOR_ALPHA )
	vColor = vec4( 1.0 );
#elif defined( USE_COLOR ) || defined( USE_INSTANCING_COLOR ) || defined( USE_BATCHING_COLOR )
	vColor = vec3( 1.0 );
#endif
#ifdef USE_COLOR
	vColor *= color;
#endif
#ifdef USE_INSTANCING_COLOR
	vColor.xyz *= instanceColor.xyz;
#endif
#ifdef USE_BATCHING_COLOR
	vec3 batchingColor = getBatchingColor( getIndirectIndex( gl_DrawID ) );
	vColor.xyz *= batchingColor.xyz;
#endif`,common:`#define PI 3.141592653589793
#define PI2 6.283185307179586
#define PI_HALF 1.5707963267948966
#define RECIPROCAL_PI 0.3183098861837907
#define RECIPROCAL_PI2 0.15915494309189535
#define EPSILON 1e-6
#ifndef saturate
#define saturate( a ) clamp( a, 0.0, 1.0 )
#endif
#define whiteComplement( a ) ( 1.0 - saturate( a ) )
float pow2( const in float x ) { return x*x; }
vec3 pow2( const in vec3 x ) { return x*x; }
float pow3( const in float x ) { return x*x*x; }
float pow4( const in float x ) { float x2 = x*x; return x2*x2; }
float max3( const in vec3 v ) { return max( max( v.x, v.y ), v.z ); }
float average( const in vec3 v ) { return dot( v, vec3( 0.3333333 ) ); }
highp float rand( const in vec2 uv ) {
	const highp float a = 12.9898, b = 78.233, c = 43758.5453;
	highp float dt = dot( uv.xy, vec2( a,b ) ), sn = mod( dt, PI );
	return fract( sin( sn ) * c );
}
#ifdef HIGH_PRECISION
	float precisionSafeLength( vec3 v ) { return length( v ); }
#else
	float precisionSafeLength( vec3 v ) {
		float maxComponent = max3( abs( v ) );
		return length( v / maxComponent ) * maxComponent;
	}
#endif
struct IncidentLight {
	vec3 color;
	vec3 direction;
	bool visible;
};
struct ReflectedLight {
	vec3 directDiffuse;
	vec3 directSpecular;
	vec3 indirectDiffuse;
	vec3 indirectSpecular;
};
#ifdef USE_ALPHAHASH
	varying vec3 vPosition;
#endif
vec3 transformDirection( in vec3 dir, in mat4 matrix ) {
	return normalize( ( matrix * vec4( dir, 0.0 ) ).xyz );
}
vec3 inverseTransformDirection( in vec3 dir, in mat4 matrix ) {
	return normalize( ( vec4( dir, 0.0 ) * matrix ).xyz );
}
mat3 transposeMat3( const in mat3 m ) {
	mat3 tmp;
	tmp[ 0 ] = vec3( m[ 0 ].x, m[ 1 ].x, m[ 2 ].x );
	tmp[ 1 ] = vec3( m[ 0 ].y, m[ 1 ].y, m[ 2 ].y );
	tmp[ 2 ] = vec3( m[ 0 ].z, m[ 1 ].z, m[ 2 ].z );
	return tmp;
}
bool isPerspectiveMatrix( mat4 m ) {
	return m[ 2 ][ 3 ] == - 1.0;
}
vec2 equirectUv( in vec3 dir ) {
	float u = atan( dir.z, dir.x ) * RECIPROCAL_PI2 + 0.5;
	float v = asin( clamp( dir.y, - 1.0, 1.0 ) ) * RECIPROCAL_PI + 0.5;
	return vec2( u, v );
}
vec3 BRDF_Lambert( const in vec3 diffuseColor ) {
	return RECIPROCAL_PI * diffuseColor;
}
vec3 F_Schlick( const in vec3 f0, const in float f90, const in float dotVH ) {
	float fresnel = exp2( ( - 5.55473 * dotVH - 6.98316 ) * dotVH );
	return f0 * ( 1.0 - fresnel ) + ( f90 * fresnel );
}
float F_Schlick( const in float f0, const in float f90, const in float dotVH ) {
	float fresnel = exp2( ( - 5.55473 * dotVH - 6.98316 ) * dotVH );
	return f0 * ( 1.0 - fresnel ) + ( f90 * fresnel );
} // validated`,cube_uv_reflection_fragment:`#ifdef ENVMAP_TYPE_CUBE_UV
	#define cubeUV_minMipLevel 4.0
	#define cubeUV_minTileSize 16.0
	float getFace( vec3 direction ) {
		vec3 absDirection = abs( direction );
		float face = - 1.0;
		if ( absDirection.x > absDirection.z ) {
			if ( absDirection.x > absDirection.y )
				face = direction.x > 0.0 ? 0.0 : 3.0;
			else
				face = direction.y > 0.0 ? 1.0 : 4.0;
		} else {
			if ( absDirection.z > absDirection.y )
				face = direction.z > 0.0 ? 2.0 : 5.0;
			else
				face = direction.y > 0.0 ? 1.0 : 4.0;
		}
		return face;
	}
	vec2 getUV( vec3 direction, float face ) {
		vec2 uv;
		if ( face == 0.0 ) {
			uv = vec2( direction.z, direction.y ) / abs( direction.x );
		} else if ( face == 1.0 ) {
			uv = vec2( - direction.x, - direction.z ) / abs( direction.y );
		} else if ( face == 2.0 ) {
			uv = vec2( - direction.x, direction.y ) / abs( direction.z );
		} else if ( face == 3.0 ) {
			uv = vec2( - direction.z, direction.y ) / abs( direction.x );
		} else if ( face == 4.0 ) {
			uv = vec2( - direction.x, direction.z ) / abs( direction.y );
		} else {
			uv = vec2( direction.x, direction.y ) / abs( direction.z );
		}
		return 0.5 * ( uv + 1.0 );
	}
	vec3 bilinearCubeUV( sampler2D envMap, vec3 direction, float mipInt ) {
		float face = getFace( direction );
		float filterInt = max( cubeUV_minMipLevel - mipInt, 0.0 );
		mipInt = max( mipInt, cubeUV_minMipLevel );
		float faceSize = exp2( mipInt );
		highp vec2 uv = getUV( direction, face ) * ( faceSize - 2.0 ) + 1.0;
		if ( face > 2.0 ) {
			uv.y += faceSize;
			face -= 3.0;
		}
		uv.x += face * faceSize;
		uv.x += filterInt * 3.0 * cubeUV_minTileSize;
		uv.y += 4.0 * ( exp2( CUBEUV_MAX_MIP ) - faceSize );
		uv.x *= CUBEUV_TEXEL_WIDTH;
		uv.y *= CUBEUV_TEXEL_HEIGHT;
		#ifdef texture2DGradEXT
			return texture2DGradEXT( envMap, uv, vec2( 0.0 ), vec2( 0.0 ) ).rgb;
		#else
			return texture2D( envMap, uv ).rgb;
		#endif
	}
	#define cubeUV_r0 1.0
	#define cubeUV_m0 - 2.0
	#define cubeUV_r1 0.8
	#define cubeUV_m1 - 1.0
	#define cubeUV_r4 0.4
	#define cubeUV_m4 2.0
	#define cubeUV_r5 0.305
	#define cubeUV_m5 3.0
	#define cubeUV_r6 0.21
	#define cubeUV_m6 4.0
	float roughnessToMip( float roughness ) {
		float mip = 0.0;
		if ( roughness >= cubeUV_r1 ) {
			mip = ( cubeUV_r0 - roughness ) * ( cubeUV_m1 - cubeUV_m0 ) / ( cubeUV_r0 - cubeUV_r1 ) + cubeUV_m0;
		} else if ( roughness >= cubeUV_r4 ) {
			mip = ( cubeUV_r1 - roughness ) * ( cubeUV_m4 - cubeUV_m1 ) / ( cubeUV_r1 - cubeUV_r4 ) + cubeUV_m1;
		} else if ( roughness >= cubeUV_r5 ) {
			mip = ( cubeUV_r4 - roughness ) * ( cubeUV_m5 - cubeUV_m4 ) / ( cubeUV_r4 - cubeUV_r5 ) + cubeUV_m4;
		} else if ( roughness >= cubeUV_r6 ) {
			mip = ( cubeUV_r5 - roughness ) * ( cubeUV_m6 - cubeUV_m5 ) / ( cubeUV_r5 - cubeUV_r6 ) + cubeUV_m5;
		} else {
			mip = - 2.0 * log2( 1.16 * roughness );		}
		return mip;
	}
	vec4 textureCubeUV( sampler2D envMap, vec3 sampleDir, float roughness ) {
		float mip = clamp( roughnessToMip( roughness ), cubeUV_m0, CUBEUV_MAX_MIP );
		float mipF = fract( mip );
		float mipInt = floor( mip );
		vec3 color0 = bilinearCubeUV( envMap, sampleDir, mipInt );
		if ( mipF == 0.0 ) {
			return vec4( color0, 1.0 );
		} else {
			vec3 color1 = bilinearCubeUV( envMap, sampleDir, mipInt + 1.0 );
			return vec4( mix( color0, color1, mipF ), 1.0 );
		}
	}
#endif`,defaultnormal_vertex:`vec3 transformedNormal = objectNormal;
#ifdef USE_TANGENT
	vec3 transformedTangent = objectTangent;
#endif
#ifdef USE_BATCHING
	mat3 bm = mat3( batchingMatrix );
	transformedNormal /= vec3( dot( bm[ 0 ], bm[ 0 ] ), dot( bm[ 1 ], bm[ 1 ] ), dot( bm[ 2 ], bm[ 2 ] ) );
	transformedNormal = bm * transformedNormal;
	#ifdef USE_TANGENT
		transformedTangent = bm * transformedTangent;
	#endif
#endif
#ifdef USE_INSTANCING
	mat3 im = mat3( instanceMatrix );
	transformedNormal /= vec3( dot( im[ 0 ], im[ 0 ] ), dot( im[ 1 ], im[ 1 ] ), dot( im[ 2 ], im[ 2 ] ) );
	transformedNormal = im * transformedNormal;
	#ifdef USE_TANGENT
		transformedTangent = im * transformedTangent;
	#endif
#endif
transformedNormal = normalMatrix * transformedNormal;
#ifdef FLIP_SIDED
	transformedNormal = - transformedNormal;
#endif
#ifdef USE_TANGENT
	transformedTangent = ( modelViewMatrix * vec4( transformedTangent, 0.0 ) ).xyz;
	#ifdef FLIP_SIDED
		transformedTangent = - transformedTangent;
	#endif
#endif`,displacementmap_pars_vertex:`#ifdef USE_DISPLACEMENTMAP
	uniform sampler2D displacementMap;
	uniform float displacementScale;
	uniform float displacementBias;
#endif`,displacementmap_vertex:`#ifdef USE_DISPLACEMENTMAP
	transformed += normalize( objectNormal ) * ( texture2D( displacementMap, vDisplacementMapUv ).x * displacementScale + displacementBias );
#endif`,emissivemap_fragment:`#ifdef USE_EMISSIVEMAP
	vec4 emissiveColor = texture2D( emissiveMap, vEmissiveMapUv );
	#ifdef DECODE_VIDEO_TEXTURE_EMISSIVE
		emissiveColor = sRGBTransferEOTF( emissiveColor );
	#endif
	totalEmissiveRadiance *= emissiveColor.rgb;
#endif`,emissivemap_pars_fragment:`#ifdef USE_EMISSIVEMAP
	uniform sampler2D emissiveMap;
#endif`,colorspace_fragment:"gl_FragColor = linearToOutputTexel( gl_FragColor );",colorspace_pars_fragment:`vec4 LinearTransferOETF( in vec4 value ) {
	return value;
}
vec4 sRGBTransferEOTF( in vec4 value ) {
	return vec4( mix( pow( value.rgb * 0.9478672986 + vec3( 0.0521327014 ), vec3( 2.4 ) ), value.rgb * 0.0773993808, vec3( lessThanEqual( value.rgb, vec3( 0.04045 ) ) ) ), value.a );
}
vec4 sRGBTransferOETF( in vec4 value ) {
	return vec4( mix( pow( value.rgb, vec3( 0.41666 ) ) * 1.055 - vec3( 0.055 ), value.rgb * 12.92, vec3( lessThanEqual( value.rgb, vec3( 0.0031308 ) ) ) ), value.a );
}`,envmap_fragment:`#ifdef USE_ENVMAP
	#ifdef ENV_WORLDPOS
		vec3 cameraToFrag;
		if ( isOrthographic ) {
			cameraToFrag = normalize( vec3( - viewMatrix[ 0 ][ 2 ], - viewMatrix[ 1 ][ 2 ], - viewMatrix[ 2 ][ 2 ] ) );
		} else {
			cameraToFrag = normalize( vWorldPosition - cameraPosition );
		}
		vec3 worldNormal = inverseTransformDirection( normal, viewMatrix );
		#ifdef ENVMAP_MODE_REFLECTION
			vec3 reflectVec = reflect( cameraToFrag, worldNormal );
		#else
			vec3 reflectVec = refract( cameraToFrag, worldNormal, refractionRatio );
		#endif
	#else
		vec3 reflectVec = vReflect;
	#endif
	#ifdef ENVMAP_TYPE_CUBE
		vec4 envColor = textureCube( envMap, envMapRotation * vec3( flipEnvMap * reflectVec.x, reflectVec.yz ) );
	#else
		vec4 envColor = vec4( 0.0 );
	#endif
	#ifdef ENVMAP_BLENDING_MULTIPLY
		outgoingLight = mix( outgoingLight, outgoingLight * envColor.xyz, specularStrength * reflectivity );
	#elif defined( ENVMAP_BLENDING_MIX )
		outgoingLight = mix( outgoingLight, envColor.xyz, specularStrength * reflectivity );
	#elif defined( ENVMAP_BLENDING_ADD )
		outgoingLight += envColor.xyz * specularStrength * reflectivity;
	#endif
#endif`,envmap_common_pars_fragment:`#ifdef USE_ENVMAP
	uniform float envMapIntensity;
	uniform float flipEnvMap;
	uniform mat3 envMapRotation;
	#ifdef ENVMAP_TYPE_CUBE
		uniform samplerCube envMap;
	#else
		uniform sampler2D envMap;
	#endif
	
#endif`,envmap_pars_fragment:`#ifdef USE_ENVMAP
	uniform float reflectivity;
	#if defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) || defined( PHONG ) || defined( LAMBERT )
		#define ENV_WORLDPOS
	#endif
	#ifdef ENV_WORLDPOS
		varying vec3 vWorldPosition;
		uniform float refractionRatio;
	#else
		varying vec3 vReflect;
	#endif
#endif`,envmap_pars_vertex:`#ifdef USE_ENVMAP
	#if defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) || defined( PHONG ) || defined( LAMBERT )
		#define ENV_WORLDPOS
	#endif
	#ifdef ENV_WORLDPOS
		
		varying vec3 vWorldPosition;
	#else
		varying vec3 vReflect;
		uniform float refractionRatio;
	#endif
#endif`,envmap_physical_pars_fragment:`#ifdef USE_ENVMAP
	vec3 getIBLIrradiance( const in vec3 normal ) {
		#ifdef ENVMAP_TYPE_CUBE_UV
			vec3 worldNormal = inverseTransformDirection( normal, viewMatrix );
			vec4 envMapColor = textureCubeUV( envMap, envMapRotation * worldNormal, 1.0 );
			return PI * envMapColor.rgb * envMapIntensity;
		#else
			return vec3( 0.0 );
		#endif
	}
	vec3 getIBLRadiance( const in vec3 viewDir, const in vec3 normal, const in float roughness ) {
		#ifdef ENVMAP_TYPE_CUBE_UV
			vec3 reflectVec = reflect( - viewDir, normal );
			reflectVec = normalize( mix( reflectVec, normal, roughness * roughness) );
			reflectVec = inverseTransformDirection( reflectVec, viewMatrix );
			vec4 envMapColor = textureCubeUV( envMap, envMapRotation * reflectVec, roughness );
			return envMapColor.rgb * envMapIntensity;
		#else
			return vec3( 0.0 );
		#endif
	}
	#ifdef USE_ANISOTROPY
		vec3 getIBLAnisotropyRadiance( const in vec3 viewDir, const in vec3 normal, const in float roughness, const in vec3 bitangent, const in float anisotropy ) {
			#ifdef ENVMAP_TYPE_CUBE_UV
				vec3 bentNormal = cross( bitangent, viewDir );
				bentNormal = normalize( cross( bentNormal, bitangent ) );
				bentNormal = normalize( mix( bentNormal, normal, pow2( pow2( 1.0 - anisotropy * ( 1.0 - roughness ) ) ) ) );
				return getIBLRadiance( viewDir, bentNormal, roughness );
			#else
				return vec3( 0.0 );
			#endif
		}
	#endif
#endif`,envmap_vertex:`#ifdef USE_ENVMAP
	#ifdef ENV_WORLDPOS
		vWorldPosition = worldPosition.xyz;
	#else
		vec3 cameraToVertex;
		if ( isOrthographic ) {
			cameraToVertex = normalize( vec3( - viewMatrix[ 0 ][ 2 ], - viewMatrix[ 1 ][ 2 ], - viewMatrix[ 2 ][ 2 ] ) );
		} else {
			cameraToVertex = normalize( worldPosition.xyz - cameraPosition );
		}
		vec3 worldNormal = inverseTransformDirection( transformedNormal, viewMatrix );
		#ifdef ENVMAP_MODE_REFLECTION
			vReflect = reflect( cameraToVertex, worldNormal );
		#else
			vReflect = refract( cameraToVertex, worldNormal, refractionRatio );
		#endif
	#endif
#endif`,fog_vertex:`#ifdef USE_FOG
	vFogDepth = - mvPosition.z;
#endif`,fog_pars_vertex:`#ifdef USE_FOG
	varying float vFogDepth;
#endif`,fog_fragment:`#ifdef USE_FOG
	#ifdef FOG_EXP2
		float fogFactor = 1.0 - exp( - fogDensity * fogDensity * vFogDepth * vFogDepth );
	#else
		float fogFactor = smoothstep( fogNear, fogFar, vFogDepth );
	#endif
	gl_FragColor.rgb = mix( gl_FragColor.rgb, fogColor, fogFactor );
#endif`,fog_pars_fragment:`#ifdef USE_FOG
	uniform vec3 fogColor;
	varying float vFogDepth;
	#ifdef FOG_EXP2
		uniform float fogDensity;
	#else
		uniform float fogNear;
		uniform float fogFar;
	#endif
#endif`,gradientmap_pars_fragment:`#ifdef USE_GRADIENTMAP
	uniform sampler2D gradientMap;
#endif
vec3 getGradientIrradiance( vec3 normal, vec3 lightDirection ) {
	float dotNL = dot( normal, lightDirection );
	vec2 coord = vec2( dotNL * 0.5 + 0.5, 0.0 );
	#ifdef USE_GRADIENTMAP
		return vec3( texture2D( gradientMap, coord ).r );
	#else
		vec2 fw = fwidth( coord ) * 0.5;
		return mix( vec3( 0.7 ), vec3( 1.0 ), smoothstep( 0.7 - fw.x, 0.7 + fw.x, coord.x ) );
	#endif
}`,lightmap_pars_fragment:`#ifdef USE_LIGHTMAP
	uniform sampler2D lightMap;
	uniform float lightMapIntensity;
#endif`,lights_lambert_fragment:`LambertMaterial material;
material.diffuseColor = diffuseColor.rgb;
material.specularStrength = specularStrength;`,lights_lambert_pars_fragment:`varying vec3 vViewPosition;
struct LambertMaterial {
	vec3 diffuseColor;
	float specularStrength;
};
void RE_Direct_Lambert( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in LambertMaterial material, inout ReflectedLight reflectedLight ) {
	float dotNL = saturate( dot( geometryNormal, directLight.direction ) );
	vec3 irradiance = dotNL * directLight.color;
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
void RE_IndirectDiffuse_Lambert( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in LambertMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
#define RE_Direct				RE_Direct_Lambert
#define RE_IndirectDiffuse		RE_IndirectDiffuse_Lambert`,lights_pars_begin:`uniform bool receiveShadow;
uniform vec3 ambientLightColor;
#if defined( USE_LIGHT_PROBES )
	uniform vec3 lightProbe[ 9 ];
#endif
vec3 shGetIrradianceAt( in vec3 normal, in vec3 shCoefficients[ 9 ] ) {
	float x = normal.x, y = normal.y, z = normal.z;
	vec3 result = shCoefficients[ 0 ] * 0.886227;
	result += shCoefficients[ 1 ] * 2.0 * 0.511664 * y;
	result += shCoefficients[ 2 ] * 2.0 * 0.511664 * z;
	result += shCoefficients[ 3 ] * 2.0 * 0.511664 * x;
	result += shCoefficients[ 4 ] * 2.0 * 0.429043 * x * y;
	result += shCoefficients[ 5 ] * 2.0 * 0.429043 * y * z;
	result += shCoefficients[ 6 ] * ( 0.743125 * z * z - 0.247708 );
	result += shCoefficients[ 7 ] * 2.0 * 0.429043 * x * z;
	result += shCoefficients[ 8 ] * 0.429043 * ( x * x - y * y );
	return result;
}
vec3 getLightProbeIrradiance( const in vec3 lightProbe[ 9 ], const in vec3 normal ) {
	vec3 worldNormal = inverseTransformDirection( normal, viewMatrix );
	vec3 irradiance = shGetIrradianceAt( worldNormal, lightProbe );
	return irradiance;
}
vec3 getAmbientLightIrradiance( const in vec3 ambientLightColor ) {
	vec3 irradiance = ambientLightColor;
	return irradiance;
}
float getDistanceAttenuation( const in float lightDistance, const in float cutoffDistance, const in float decayExponent ) {
	float distanceFalloff = 1.0 / max( pow( lightDistance, decayExponent ), 0.01 );
	if ( cutoffDistance > 0.0 ) {
		distanceFalloff *= pow2( saturate( 1.0 - pow4( lightDistance / cutoffDistance ) ) );
	}
	return distanceFalloff;
}
float getSpotAttenuation( const in float coneCosine, const in float penumbraCosine, const in float angleCosine ) {
	return smoothstep( coneCosine, penumbraCosine, angleCosine );
}
#if NUM_DIR_LIGHTS > 0
	struct DirectionalLight {
		vec3 direction;
		vec3 color;
	};
	uniform DirectionalLight directionalLights[ NUM_DIR_LIGHTS ];
	void getDirectionalLightInfo( const in DirectionalLight directionalLight, out IncidentLight light ) {
		light.color = directionalLight.color;
		light.direction = directionalLight.direction;
		light.visible = true;
	}
#endif
#if NUM_POINT_LIGHTS > 0
	struct PointLight {
		vec3 position;
		vec3 color;
		float distance;
		float decay;
	};
	uniform PointLight pointLights[ NUM_POINT_LIGHTS ];
	void getPointLightInfo( const in PointLight pointLight, const in vec3 geometryPosition, out IncidentLight light ) {
		vec3 lVector = pointLight.position - geometryPosition;
		light.direction = normalize( lVector );
		float lightDistance = length( lVector );
		light.color = pointLight.color;
		light.color *= getDistanceAttenuation( lightDistance, pointLight.distance, pointLight.decay );
		light.visible = ( light.color != vec3( 0.0 ) );
	}
#endif
#if NUM_SPOT_LIGHTS > 0
	struct SpotLight {
		vec3 position;
		vec3 direction;
		vec3 color;
		float distance;
		float decay;
		float coneCos;
		float penumbraCos;
	};
	uniform SpotLight spotLights[ NUM_SPOT_LIGHTS ];
	void getSpotLightInfo( const in SpotLight spotLight, const in vec3 geometryPosition, out IncidentLight light ) {
		vec3 lVector = spotLight.position - geometryPosition;
		light.direction = normalize( lVector );
		float angleCos = dot( light.direction, spotLight.direction );
		float spotAttenuation = getSpotAttenuation( spotLight.coneCos, spotLight.penumbraCos, angleCos );
		if ( spotAttenuation > 0.0 ) {
			float lightDistance = length( lVector );
			light.color = spotLight.color * spotAttenuation;
			light.color *= getDistanceAttenuation( lightDistance, spotLight.distance, spotLight.decay );
			light.visible = ( light.color != vec3( 0.0 ) );
		} else {
			light.color = vec3( 0.0 );
			light.visible = false;
		}
	}
#endif
#if NUM_RECT_AREA_LIGHTS > 0
	struct RectAreaLight {
		vec3 color;
		vec3 position;
		vec3 halfWidth;
		vec3 halfHeight;
	};
	uniform sampler2D ltc_1;	uniform sampler2D ltc_2;
	uniform RectAreaLight rectAreaLights[ NUM_RECT_AREA_LIGHTS ];
#endif
#if NUM_HEMI_LIGHTS > 0
	struct HemisphereLight {
		vec3 direction;
		vec3 skyColor;
		vec3 groundColor;
	};
	uniform HemisphereLight hemisphereLights[ NUM_HEMI_LIGHTS ];
	vec3 getHemisphereLightIrradiance( const in HemisphereLight hemiLight, const in vec3 normal ) {
		float dotNL = dot( normal, hemiLight.direction );
		float hemiDiffuseWeight = 0.5 * dotNL + 0.5;
		vec3 irradiance = mix( hemiLight.groundColor, hemiLight.skyColor, hemiDiffuseWeight );
		return irradiance;
	}
#endif`,lights_toon_fragment:`ToonMaterial material;
material.diffuseColor = diffuseColor.rgb;`,lights_toon_pars_fragment:`varying vec3 vViewPosition;
struct ToonMaterial {
	vec3 diffuseColor;
};
void RE_Direct_Toon( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in ToonMaterial material, inout ReflectedLight reflectedLight ) {
	vec3 irradiance = getGradientIrradiance( geometryNormal, directLight.direction ) * directLight.color;
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
void RE_IndirectDiffuse_Toon( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in ToonMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
#define RE_Direct				RE_Direct_Toon
#define RE_IndirectDiffuse		RE_IndirectDiffuse_Toon`,lights_phong_fragment:`BlinnPhongMaterial material;
material.diffuseColor = diffuseColor.rgb;
material.specularColor = specular;
material.specularShininess = shininess;
material.specularStrength = specularStrength;`,lights_phong_pars_fragment:`varying vec3 vViewPosition;
struct BlinnPhongMaterial {
	vec3 diffuseColor;
	vec3 specularColor;
	float specularShininess;
	float specularStrength;
};
void RE_Direct_BlinnPhong( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in BlinnPhongMaterial material, inout ReflectedLight reflectedLight ) {
	float dotNL = saturate( dot( geometryNormal, directLight.direction ) );
	vec3 irradiance = dotNL * directLight.color;
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
	reflectedLight.directSpecular += irradiance * BRDF_BlinnPhong( directLight.direction, geometryViewDir, geometryNormal, material.specularColor, material.specularShininess ) * material.specularStrength;
}
void RE_IndirectDiffuse_BlinnPhong( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in BlinnPhongMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
#define RE_Direct				RE_Direct_BlinnPhong
#define RE_IndirectDiffuse		RE_IndirectDiffuse_BlinnPhong`,lights_physical_fragment:`PhysicalMaterial material;
material.diffuseColor = diffuseColor.rgb * ( 1.0 - metalnessFactor );
vec3 dxy = max( abs( dFdx( nonPerturbedNormal ) ), abs( dFdy( nonPerturbedNormal ) ) );
float geometryRoughness = max( max( dxy.x, dxy.y ), dxy.z );
material.roughness = max( roughnessFactor, 0.0525 );material.roughness += geometryRoughness;
material.roughness = min( material.roughness, 1.0 );
#ifdef IOR
	material.ior = ior;
	#ifdef USE_SPECULAR
		float specularIntensityFactor = specularIntensity;
		vec3 specularColorFactor = specularColor;
		#ifdef USE_SPECULAR_COLORMAP
			specularColorFactor *= texture2D( specularColorMap, vSpecularColorMapUv ).rgb;
		#endif
		#ifdef USE_SPECULAR_INTENSITYMAP
			specularIntensityFactor *= texture2D( specularIntensityMap, vSpecularIntensityMapUv ).a;
		#endif
		material.specularF90 = mix( specularIntensityFactor, 1.0, metalnessFactor );
	#else
		float specularIntensityFactor = 1.0;
		vec3 specularColorFactor = vec3( 1.0 );
		material.specularF90 = 1.0;
	#endif
	material.specularColor = mix( min( pow2( ( material.ior - 1.0 ) / ( material.ior + 1.0 ) ) * specularColorFactor, vec3( 1.0 ) ) * specularIntensityFactor, diffuseColor.rgb, metalnessFactor );
#else
	material.specularColor = mix( vec3( 0.04 ), diffuseColor.rgb, metalnessFactor );
	material.specularF90 = 1.0;
#endif
#ifdef USE_CLEARCOAT
	material.clearcoat = clearcoat;
	material.clearcoatRoughness = clearcoatRoughness;
	material.clearcoatF0 = vec3( 0.04 );
	material.clearcoatF90 = 1.0;
	#ifdef USE_CLEARCOATMAP
		material.clearcoat *= texture2D( clearcoatMap, vClearcoatMapUv ).x;
	#endif
	#ifdef USE_CLEARCOAT_ROUGHNESSMAP
		material.clearcoatRoughness *= texture2D( clearcoatRoughnessMap, vClearcoatRoughnessMapUv ).y;
	#endif
	material.clearcoat = saturate( material.clearcoat );	material.clearcoatRoughness = max( material.clearcoatRoughness, 0.0525 );
	material.clearcoatRoughness += geometryRoughness;
	material.clearcoatRoughness = min( material.clearcoatRoughness, 1.0 );
#endif
#ifdef USE_DISPERSION
	material.dispersion = dispersion;
#endif
#ifdef USE_IRIDESCENCE
	material.iridescence = iridescence;
	material.iridescenceIOR = iridescenceIOR;
	#ifdef USE_IRIDESCENCEMAP
		material.iridescence *= texture2D( iridescenceMap, vIridescenceMapUv ).r;
	#endif
	#ifdef USE_IRIDESCENCE_THICKNESSMAP
		material.iridescenceThickness = (iridescenceThicknessMaximum - iridescenceThicknessMinimum) * texture2D( iridescenceThicknessMap, vIridescenceThicknessMapUv ).g + iridescenceThicknessMinimum;
	#else
		material.iridescenceThickness = iridescenceThicknessMaximum;
	#endif
#endif
#ifdef USE_SHEEN
	material.sheenColor = sheenColor;
	#ifdef USE_SHEEN_COLORMAP
		material.sheenColor *= texture2D( sheenColorMap, vSheenColorMapUv ).rgb;
	#endif
	material.sheenRoughness = clamp( sheenRoughness, 0.07, 1.0 );
	#ifdef USE_SHEEN_ROUGHNESSMAP
		material.sheenRoughness *= texture2D( sheenRoughnessMap, vSheenRoughnessMapUv ).a;
	#endif
#endif
#ifdef USE_ANISOTROPY
	#ifdef USE_ANISOTROPYMAP
		mat2 anisotropyMat = mat2( anisotropyVector.x, anisotropyVector.y, - anisotropyVector.y, anisotropyVector.x );
		vec3 anisotropyPolar = texture2D( anisotropyMap, vAnisotropyMapUv ).rgb;
		vec2 anisotropyV = anisotropyMat * normalize( 2.0 * anisotropyPolar.rg - vec2( 1.0 ) ) * anisotropyPolar.b;
	#else
		vec2 anisotropyV = anisotropyVector;
	#endif
	material.anisotropy = length( anisotropyV );
	if( material.anisotropy == 0.0 ) {
		anisotropyV = vec2( 1.0, 0.0 );
	} else {
		anisotropyV /= material.anisotropy;
		material.anisotropy = saturate( material.anisotropy );
	}
	material.alphaT = mix( pow2( material.roughness ), 1.0, pow2( material.anisotropy ) );
	material.anisotropyT = tbn[ 0 ] * anisotropyV.x + tbn[ 1 ] * anisotropyV.y;
	material.anisotropyB = tbn[ 1 ] * anisotropyV.x - tbn[ 0 ] * anisotropyV.y;
#endif`,lights_physical_pars_fragment:`struct PhysicalMaterial {
	vec3 diffuseColor;
	float roughness;
	vec3 specularColor;
	float specularF90;
	float dispersion;
	#ifdef USE_CLEARCOAT
		float clearcoat;
		float clearcoatRoughness;
		vec3 clearcoatF0;
		float clearcoatF90;
	#endif
	#ifdef USE_IRIDESCENCE
		float iridescence;
		float iridescenceIOR;
		float iridescenceThickness;
		vec3 iridescenceFresnel;
		vec3 iridescenceF0;
	#endif
	#ifdef USE_SHEEN
		vec3 sheenColor;
		float sheenRoughness;
	#endif
	#ifdef IOR
		float ior;
	#endif
	#ifdef USE_TRANSMISSION
		float transmission;
		float transmissionAlpha;
		float thickness;
		float attenuationDistance;
		vec3 attenuationColor;
	#endif
	#ifdef USE_ANISOTROPY
		float anisotropy;
		float alphaT;
		vec3 anisotropyT;
		vec3 anisotropyB;
	#endif
};
vec3 clearcoatSpecularDirect = vec3( 0.0 );
vec3 clearcoatSpecularIndirect = vec3( 0.0 );
vec3 sheenSpecularDirect = vec3( 0.0 );
vec3 sheenSpecularIndirect = vec3(0.0 );
vec3 Schlick_to_F0( const in vec3 f, const in float f90, const in float dotVH ) {
    float x = clamp( 1.0 - dotVH, 0.0, 1.0 );
    float x2 = x * x;
    float x5 = clamp( x * x2 * x2, 0.0, 0.9999 );
    return ( f - vec3( f90 ) * x5 ) / ( 1.0 - x5 );
}
float V_GGX_SmithCorrelated( const in float alpha, const in float dotNL, const in float dotNV ) {
	float a2 = pow2( alpha );
	float gv = dotNL * sqrt( a2 + ( 1.0 - a2 ) * pow2( dotNV ) );
	float gl = dotNV * sqrt( a2 + ( 1.0 - a2 ) * pow2( dotNL ) );
	return 0.5 / max( gv + gl, EPSILON );
}
float D_GGX( const in float alpha, const in float dotNH ) {
	float a2 = pow2( alpha );
	float denom = pow2( dotNH ) * ( a2 - 1.0 ) + 1.0;
	return RECIPROCAL_PI * a2 / pow2( denom );
}
#ifdef USE_ANISOTROPY
	float V_GGX_SmithCorrelated_Anisotropic( const in float alphaT, const in float alphaB, const in float dotTV, const in float dotBV, const in float dotTL, const in float dotBL, const in float dotNV, const in float dotNL ) {
		float gv = dotNL * length( vec3( alphaT * dotTV, alphaB * dotBV, dotNV ) );
		float gl = dotNV * length( vec3( alphaT * dotTL, alphaB * dotBL, dotNL ) );
		float v = 0.5 / ( gv + gl );
		return saturate(v);
	}
	float D_GGX_Anisotropic( const in float alphaT, const in float alphaB, const in float dotNH, const in float dotTH, const in float dotBH ) {
		float a2 = alphaT * alphaB;
		highp vec3 v = vec3( alphaB * dotTH, alphaT * dotBH, a2 * dotNH );
		highp float v2 = dot( v, v );
		float w2 = a2 / v2;
		return RECIPROCAL_PI * a2 * pow2 ( w2 );
	}
#endif
#ifdef USE_CLEARCOAT
	vec3 BRDF_GGX_Clearcoat( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, const in PhysicalMaterial material) {
		vec3 f0 = material.clearcoatF0;
		float f90 = material.clearcoatF90;
		float roughness = material.clearcoatRoughness;
		float alpha = pow2( roughness );
		vec3 halfDir = normalize( lightDir + viewDir );
		float dotNL = saturate( dot( normal, lightDir ) );
		float dotNV = saturate( dot( normal, viewDir ) );
		float dotNH = saturate( dot( normal, halfDir ) );
		float dotVH = saturate( dot( viewDir, halfDir ) );
		vec3 F = F_Schlick( f0, f90, dotVH );
		float V = V_GGX_SmithCorrelated( alpha, dotNL, dotNV );
		float D = D_GGX( alpha, dotNH );
		return F * ( V * D );
	}
#endif
vec3 BRDF_GGX( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, const in PhysicalMaterial material ) {
	vec3 f0 = material.specularColor;
	float f90 = material.specularF90;
	float roughness = material.roughness;
	float alpha = pow2( roughness );
	vec3 halfDir = normalize( lightDir + viewDir );
	float dotNL = saturate( dot( normal, lightDir ) );
	float dotNV = saturate( dot( normal, viewDir ) );
	float dotNH = saturate( dot( normal, halfDir ) );
	float dotVH = saturate( dot( viewDir, halfDir ) );
	vec3 F = F_Schlick( f0, f90, dotVH );
	#ifdef USE_IRIDESCENCE
		F = mix( F, material.iridescenceFresnel, material.iridescence );
	#endif
	#ifdef USE_ANISOTROPY
		float dotTL = dot( material.anisotropyT, lightDir );
		float dotTV = dot( material.anisotropyT, viewDir );
		float dotTH = dot( material.anisotropyT, halfDir );
		float dotBL = dot( material.anisotropyB, lightDir );
		float dotBV = dot( material.anisotropyB, viewDir );
		float dotBH = dot( material.anisotropyB, halfDir );
		float V = V_GGX_SmithCorrelated_Anisotropic( material.alphaT, alpha, dotTV, dotBV, dotTL, dotBL, dotNV, dotNL );
		float D = D_GGX_Anisotropic( material.alphaT, alpha, dotNH, dotTH, dotBH );
	#else
		float V = V_GGX_SmithCorrelated( alpha, dotNL, dotNV );
		float D = D_GGX( alpha, dotNH );
	#endif
	return F * ( V * D );
}
vec2 LTC_Uv( const in vec3 N, const in vec3 V, const in float roughness ) {
	const float LUT_SIZE = 64.0;
	const float LUT_SCALE = ( LUT_SIZE - 1.0 ) / LUT_SIZE;
	const float LUT_BIAS = 0.5 / LUT_SIZE;
	float dotNV = saturate( dot( N, V ) );
	vec2 uv = vec2( roughness, sqrt( 1.0 - dotNV ) );
	uv = uv * LUT_SCALE + LUT_BIAS;
	return uv;
}
float LTC_ClippedSphereFormFactor( const in vec3 f ) {
	float l = length( f );
	return max( ( l * l + f.z ) / ( l + 1.0 ), 0.0 );
}
vec3 LTC_EdgeVectorFormFactor( const in vec3 v1, const in vec3 v2 ) {
	float x = dot( v1, v2 );
	float y = abs( x );
	float a = 0.8543985 + ( 0.4965155 + 0.0145206 * y ) * y;
	float b = 3.4175940 + ( 4.1616724 + y ) * y;
	float v = a / b;
	float theta_sintheta = ( x > 0.0 ) ? v : 0.5 * inversesqrt( max( 1.0 - x * x, 1e-7 ) ) - v;
	return cross( v1, v2 ) * theta_sintheta;
}
vec3 LTC_Evaluate( const in vec3 N, const in vec3 V, const in vec3 P, const in mat3 mInv, const in vec3 rectCoords[ 4 ] ) {
	vec3 v1 = rectCoords[ 1 ] - rectCoords[ 0 ];
	vec3 v2 = rectCoords[ 3 ] - rectCoords[ 0 ];
	vec3 lightNormal = cross( v1, v2 );
	if( dot( lightNormal, P - rectCoords[ 0 ] ) < 0.0 ) return vec3( 0.0 );
	vec3 T1, T2;
	T1 = normalize( V - N * dot( V, N ) );
	T2 = - cross( N, T1 );
	mat3 mat = mInv * transposeMat3( mat3( T1, T2, N ) );
	vec3 coords[ 4 ];
	coords[ 0 ] = mat * ( rectCoords[ 0 ] - P );
	coords[ 1 ] = mat * ( rectCoords[ 1 ] - P );
	coords[ 2 ] = mat * ( rectCoords[ 2 ] - P );
	coords[ 3 ] = mat * ( rectCoords[ 3 ] - P );
	coords[ 0 ] = normalize( coords[ 0 ] );
	coords[ 1 ] = normalize( coords[ 1 ] );
	coords[ 2 ] = normalize( coords[ 2 ] );
	coords[ 3 ] = normalize( coords[ 3 ] );
	vec3 vectorFormFactor = vec3( 0.0 );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 0 ], coords[ 1 ] );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 1 ], coords[ 2 ] );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 2 ], coords[ 3 ] );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 3 ], coords[ 0 ] );
	float result = LTC_ClippedSphereFormFactor( vectorFormFactor );
	return vec3( result );
}
#if defined( USE_SHEEN )
float D_Charlie( float roughness, float dotNH ) {
	float alpha = pow2( roughness );
	float invAlpha = 1.0 / alpha;
	float cos2h = dotNH * dotNH;
	float sin2h = max( 1.0 - cos2h, 0.0078125 );
	return ( 2.0 + invAlpha ) * pow( sin2h, invAlpha * 0.5 ) / ( 2.0 * PI );
}
float V_Neubelt( float dotNV, float dotNL ) {
	return saturate( 1.0 / ( 4.0 * ( dotNL + dotNV - dotNL * dotNV ) ) );
}
vec3 BRDF_Sheen( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, vec3 sheenColor, const in float sheenRoughness ) {
	vec3 halfDir = normalize( lightDir + viewDir );
	float dotNL = saturate( dot( normal, lightDir ) );
	float dotNV = saturate( dot( normal, viewDir ) );
	float dotNH = saturate( dot( normal, halfDir ) );
	float D = D_Charlie( sheenRoughness, dotNH );
	float V = V_Neubelt( dotNV, dotNL );
	return sheenColor * ( D * V );
}
#endif
float IBLSheenBRDF( const in vec3 normal, const in vec3 viewDir, const in float roughness ) {
	float dotNV = saturate( dot( normal, viewDir ) );
	float r2 = roughness * roughness;
	float a = roughness < 0.25 ? -339.2 * r2 + 161.4 * roughness - 25.9 : -8.48 * r2 + 14.3 * roughness - 9.95;
	float b = roughness < 0.25 ? 44.0 * r2 - 23.7 * roughness + 3.26 : 1.97 * r2 - 3.27 * roughness + 0.72;
	float DG = exp( a * dotNV + b ) + ( roughness < 0.25 ? 0.0 : 0.1 * ( roughness - 0.25 ) );
	return saturate( DG * RECIPROCAL_PI );
}
vec2 DFGApprox( const in vec3 normal, const in vec3 viewDir, const in float roughness ) {
	float dotNV = saturate( dot( normal, viewDir ) );
	const vec4 c0 = vec4( - 1, - 0.0275, - 0.572, 0.022 );
	const vec4 c1 = vec4( 1, 0.0425, 1.04, - 0.04 );
	vec4 r = roughness * c0 + c1;
	float a004 = min( r.x * r.x, exp2( - 9.28 * dotNV ) ) * r.x + r.y;
	vec2 fab = vec2( - 1.04, 1.04 ) * a004 + r.zw;
	return fab;
}
vec3 EnvironmentBRDF( const in vec3 normal, const in vec3 viewDir, const in vec3 specularColor, const in float specularF90, const in float roughness ) {
	vec2 fab = DFGApprox( normal, viewDir, roughness );
	return specularColor * fab.x + specularF90 * fab.y;
}
#ifdef USE_IRIDESCENCE
void computeMultiscatteringIridescence( const in vec3 normal, const in vec3 viewDir, const in vec3 specularColor, const in float specularF90, const in float iridescence, const in vec3 iridescenceF0, const in float roughness, inout vec3 singleScatter, inout vec3 multiScatter ) {
#else
void computeMultiscattering( const in vec3 normal, const in vec3 viewDir, const in vec3 specularColor, const in float specularF90, const in float roughness, inout vec3 singleScatter, inout vec3 multiScatter ) {
#endif
	vec2 fab = DFGApprox( normal, viewDir, roughness );
	#ifdef USE_IRIDESCENCE
		vec3 Fr = mix( specularColor, iridescenceF0, iridescence );
	#else
		vec3 Fr = specularColor;
	#endif
	vec3 FssEss = Fr * fab.x + specularF90 * fab.y;
	float Ess = fab.x + fab.y;
	float Ems = 1.0 - Ess;
	vec3 Favg = Fr + ( 1.0 - Fr ) * 0.047619;	vec3 Fms = FssEss * Favg / ( 1.0 - Ems * Favg );
	singleScatter += FssEss;
	multiScatter += Fms * Ems;
}
#if NUM_RECT_AREA_LIGHTS > 0
	void RE_Direct_RectArea_Physical( const in RectAreaLight rectAreaLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in PhysicalMaterial material, inout ReflectedLight reflectedLight ) {
		vec3 normal = geometryNormal;
		vec3 viewDir = geometryViewDir;
		vec3 position = geometryPosition;
		vec3 lightPos = rectAreaLight.position;
		vec3 halfWidth = rectAreaLight.halfWidth;
		vec3 halfHeight = rectAreaLight.halfHeight;
		vec3 lightColor = rectAreaLight.color;
		float roughness = material.roughness;
		vec3 rectCoords[ 4 ];
		rectCoords[ 0 ] = lightPos + halfWidth - halfHeight;		rectCoords[ 1 ] = lightPos - halfWidth - halfHeight;
		rectCoords[ 2 ] = lightPos - halfWidth + halfHeight;
		rectCoords[ 3 ] = lightPos + halfWidth + halfHeight;
		vec2 uv = LTC_Uv( normal, viewDir, roughness );
		vec4 t1 = texture2D( ltc_1, uv );
		vec4 t2 = texture2D( ltc_2, uv );
		mat3 mInv = mat3(
			vec3( t1.x, 0, t1.y ),
			vec3(    0, 1,    0 ),
			vec3( t1.z, 0, t1.w )
		);
		vec3 fresnel = ( material.specularColor * t2.x + ( vec3( 1.0 ) - material.specularColor ) * t2.y );
		reflectedLight.directSpecular += lightColor * fresnel * LTC_Evaluate( normal, viewDir, position, mInv, rectCoords );
		reflectedLight.directDiffuse += lightColor * material.diffuseColor * LTC_Evaluate( normal, viewDir, position, mat3( 1.0 ), rectCoords );
	}
#endif
void RE_Direct_Physical( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in PhysicalMaterial material, inout ReflectedLight reflectedLight ) {
	float dotNL = saturate( dot( geometryNormal, directLight.direction ) );
	vec3 irradiance = dotNL * directLight.color;
	#ifdef USE_CLEARCOAT
		float dotNLcc = saturate( dot( geometryClearcoatNormal, directLight.direction ) );
		vec3 ccIrradiance = dotNLcc * directLight.color;
		clearcoatSpecularDirect += ccIrradiance * BRDF_GGX_Clearcoat( directLight.direction, geometryViewDir, geometryClearcoatNormal, material );
	#endif
	#ifdef USE_SHEEN
		sheenSpecularDirect += irradiance * BRDF_Sheen( directLight.direction, geometryViewDir, geometryNormal, material.sheenColor, material.sheenRoughness );
	#endif
	reflectedLight.directSpecular += irradiance * BRDF_GGX( directLight.direction, geometryViewDir, geometryNormal, material );
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
void RE_IndirectDiffuse_Physical( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in PhysicalMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
void RE_IndirectSpecular_Physical( const in vec3 radiance, const in vec3 irradiance, const in vec3 clearcoatRadiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in PhysicalMaterial material, inout ReflectedLight reflectedLight) {
	#ifdef USE_CLEARCOAT
		clearcoatSpecularIndirect += clearcoatRadiance * EnvironmentBRDF( geometryClearcoatNormal, geometryViewDir, material.clearcoatF0, material.clearcoatF90, material.clearcoatRoughness );
	#endif
	#ifdef USE_SHEEN
		sheenSpecularIndirect += irradiance * material.sheenColor * IBLSheenBRDF( geometryNormal, geometryViewDir, material.sheenRoughness );
	#endif
	vec3 singleScattering = vec3( 0.0 );
	vec3 multiScattering = vec3( 0.0 );
	vec3 cosineWeightedIrradiance = irradiance * RECIPROCAL_PI;
	#ifdef USE_IRIDESCENCE
		computeMultiscatteringIridescence( geometryNormal, geometryViewDir, material.specularColor, material.specularF90, material.iridescence, material.iridescenceFresnel, material.roughness, singleScattering, multiScattering );
	#else
		computeMultiscattering( geometryNormal, geometryViewDir, material.specularColor, material.specularF90, material.roughness, singleScattering, multiScattering );
	#endif
	vec3 totalScattering = singleScattering + multiScattering;
	vec3 diffuse = material.diffuseColor * ( 1.0 - max( max( totalScattering.r, totalScattering.g ), totalScattering.b ) );
	reflectedLight.indirectSpecular += radiance * singleScattering;
	reflectedLight.indirectSpecular += multiScattering * cosineWeightedIrradiance;
	reflectedLight.indirectDiffuse += diffuse * cosineWeightedIrradiance;
}
#define RE_Direct				RE_Direct_Physical
#define RE_Direct_RectArea		RE_Direct_RectArea_Physical
#define RE_IndirectDiffuse		RE_IndirectDiffuse_Physical
#define RE_IndirectSpecular		RE_IndirectSpecular_Physical
float computeSpecularOcclusion( const in float dotNV, const in float ambientOcclusion, const in float roughness ) {
	return saturate( pow( dotNV + ambientOcclusion, exp2( - 16.0 * roughness - 1.0 ) ) - 1.0 + ambientOcclusion );
}`,lights_fragment_begin:`
vec3 geometryPosition = - vViewPosition;
vec3 geometryNormal = normal;
vec3 geometryViewDir = ( isOrthographic ) ? vec3( 0, 0, 1 ) : normalize( vViewPosition );
vec3 geometryClearcoatNormal = vec3( 0.0 );
#ifdef USE_CLEARCOAT
	geometryClearcoatNormal = clearcoatNormal;
#endif
#ifdef USE_IRIDESCENCE
	float dotNVi = saturate( dot( normal, geometryViewDir ) );
	if ( material.iridescenceThickness == 0.0 ) {
		material.iridescence = 0.0;
	} else {
		material.iridescence = saturate( material.iridescence );
	}
	if ( material.iridescence > 0.0 ) {
		material.iridescenceFresnel = evalIridescence( 1.0, material.iridescenceIOR, dotNVi, material.iridescenceThickness, material.specularColor );
		material.iridescenceF0 = Schlick_to_F0( material.iridescenceFresnel, 1.0, dotNVi );
	}
#endif
IncidentLight directLight;
#if ( NUM_POINT_LIGHTS > 0 ) && defined( RE_Direct )
	PointLight pointLight;
	#if defined( USE_SHADOWMAP ) && NUM_POINT_LIGHT_SHADOWS > 0
	PointLightShadow pointLightShadow;
	#endif
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_POINT_LIGHTS; i ++ ) {
		pointLight = pointLights[ i ];
		getPointLightInfo( pointLight, geometryPosition, directLight );
		#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_POINT_LIGHT_SHADOWS )
		pointLightShadow = pointLightShadows[ i ];
		directLight.color *= ( directLight.visible && receiveShadow ) ? getPointShadow( pointShadowMap[ i ], pointLightShadow.shadowMapSize, pointLightShadow.shadowIntensity, pointLightShadow.shadowBias, pointLightShadow.shadowRadius, vPointShadowCoord[ i ], pointLightShadow.shadowCameraNear, pointLightShadow.shadowCameraFar ) : 1.0;
		#endif
		RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if ( NUM_SPOT_LIGHTS > 0 ) && defined( RE_Direct )
	SpotLight spotLight;
	vec4 spotColor;
	vec3 spotLightCoord;
	bool inSpotLightMap;
	#if defined( USE_SHADOWMAP ) && NUM_SPOT_LIGHT_SHADOWS > 0
	SpotLightShadow spotLightShadow;
	#endif
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_SPOT_LIGHTS; i ++ ) {
		spotLight = spotLights[ i ];
		getSpotLightInfo( spotLight, geometryPosition, directLight );
		#if ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS )
		#define SPOT_LIGHT_MAP_INDEX UNROLLED_LOOP_INDEX
		#elif ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )
		#define SPOT_LIGHT_MAP_INDEX NUM_SPOT_LIGHT_MAPS
		#else
		#define SPOT_LIGHT_MAP_INDEX ( UNROLLED_LOOP_INDEX - NUM_SPOT_LIGHT_SHADOWS + NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS )
		#endif
		#if ( SPOT_LIGHT_MAP_INDEX < NUM_SPOT_LIGHT_MAPS )
			spotLightCoord = vSpotLightCoord[ i ].xyz / vSpotLightCoord[ i ].w;
			inSpotLightMap = all( lessThan( abs( spotLightCoord * 2. - 1. ), vec3( 1.0 ) ) );
			spotColor = texture2D( spotLightMap[ SPOT_LIGHT_MAP_INDEX ], spotLightCoord.xy );
			directLight.color = inSpotLightMap ? directLight.color * spotColor.rgb : directLight.color;
		#endif
		#undef SPOT_LIGHT_MAP_INDEX
		#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )
		spotLightShadow = spotLightShadows[ i ];
		directLight.color *= ( directLight.visible && receiveShadow ) ? getShadow( spotShadowMap[ i ], spotLightShadow.shadowMapSize, spotLightShadow.shadowIntensity, spotLightShadow.shadowBias, spotLightShadow.shadowRadius, vSpotLightCoord[ i ] ) : 1.0;
		#endif
		RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if ( NUM_DIR_LIGHTS > 0 ) && defined( RE_Direct )
	DirectionalLight directionalLight;
	#if defined( USE_SHADOWMAP ) && NUM_DIR_LIGHT_SHADOWS > 0
	DirectionalLightShadow directionalLightShadow;
	#endif
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_DIR_LIGHTS; i ++ ) {
		directionalLight = directionalLights[ i ];
		getDirectionalLightInfo( directionalLight, directLight );
		#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_DIR_LIGHT_SHADOWS )
		directionalLightShadow = directionalLightShadows[ i ];
		directLight.color *= ( directLight.visible && receiveShadow ) ? getShadow( directionalShadowMap[ i ], directionalLightShadow.shadowMapSize, directionalLightShadow.shadowIntensity, directionalLightShadow.shadowBias, directionalLightShadow.shadowRadius, vDirectionalShadowCoord[ i ] ) : 1.0;
		#endif
		RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if ( NUM_RECT_AREA_LIGHTS > 0 ) && defined( RE_Direct_RectArea )
	RectAreaLight rectAreaLight;
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_RECT_AREA_LIGHTS; i ++ ) {
		rectAreaLight = rectAreaLights[ i ];
		RE_Direct_RectArea( rectAreaLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if defined( RE_IndirectDiffuse )
	vec3 iblIrradiance = vec3( 0.0 );
	vec3 irradiance = getAmbientLightIrradiance( ambientLightColor );
	#if defined( USE_LIGHT_PROBES )
		irradiance += getLightProbeIrradiance( lightProbe, geometryNormal );
	#endif
	#if ( NUM_HEMI_LIGHTS > 0 )
		#pragma unroll_loop_start
		for ( int i = 0; i < NUM_HEMI_LIGHTS; i ++ ) {
			irradiance += getHemisphereLightIrradiance( hemisphereLights[ i ], geometryNormal );
		}
		#pragma unroll_loop_end
	#endif
#endif
#if defined( RE_IndirectSpecular )
	vec3 radiance = vec3( 0.0 );
	vec3 clearcoatRadiance = vec3( 0.0 );
#endif`,lights_fragment_maps:`#if defined( RE_IndirectDiffuse )
	#ifdef USE_LIGHTMAP
		vec4 lightMapTexel = texture2D( lightMap, vLightMapUv );
		vec3 lightMapIrradiance = lightMapTexel.rgb * lightMapIntensity;
		irradiance += lightMapIrradiance;
	#endif
	#if defined( USE_ENVMAP ) && defined( STANDARD ) && defined( ENVMAP_TYPE_CUBE_UV )
		iblIrradiance += getIBLIrradiance( geometryNormal );
	#endif
#endif
#if defined( USE_ENVMAP ) && defined( RE_IndirectSpecular )
	#ifdef USE_ANISOTROPY
		radiance += getIBLAnisotropyRadiance( geometryViewDir, geometryNormal, material.roughness, material.anisotropyB, material.anisotropy );
	#else
		radiance += getIBLRadiance( geometryViewDir, geometryNormal, material.roughness );
	#endif
	#ifdef USE_CLEARCOAT
		clearcoatRadiance += getIBLRadiance( geometryViewDir, geometryClearcoatNormal, material.clearcoatRoughness );
	#endif
#endif`,lights_fragment_end:`#if defined( RE_IndirectDiffuse )
	RE_IndirectDiffuse( irradiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
#endif
#if defined( RE_IndirectSpecular )
	RE_IndirectSpecular( radiance, iblIrradiance, clearcoatRadiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
#endif`,logdepthbuf_fragment:`#if defined( USE_LOGARITHMIC_DEPTH_BUFFER )
	gl_FragDepth = vIsPerspective == 0.0 ? gl_FragCoord.z : log2( vFragDepth ) * logDepthBufFC * 0.5;
#endif`,logdepthbuf_pars_fragment:`#if defined( USE_LOGARITHMIC_DEPTH_BUFFER )
	uniform float logDepthBufFC;
	varying float vFragDepth;
	varying float vIsPerspective;
#endif`,logdepthbuf_pars_vertex:`#ifdef USE_LOGARITHMIC_DEPTH_BUFFER
	varying float vFragDepth;
	varying float vIsPerspective;
#endif`,logdepthbuf_vertex:`#ifdef USE_LOGARITHMIC_DEPTH_BUFFER
	vFragDepth = 1.0 + gl_Position.w;
	vIsPerspective = float( isPerspectiveMatrix( projectionMatrix ) );
#endif`,map_fragment:`#ifdef USE_MAP
	vec4 sampledDiffuseColor = texture2D( map, vMapUv );
	#ifdef DECODE_VIDEO_TEXTURE
		sampledDiffuseColor = sRGBTransferEOTF( sampledDiffuseColor );
	#endif
	diffuseColor *= sampledDiffuseColor;
#endif`,map_pars_fragment:`#ifdef USE_MAP
	uniform sampler2D map;
#endif`,map_particle_fragment:`#if defined( USE_MAP ) || defined( USE_ALPHAMAP )
	#if defined( USE_POINTS_UV )
		vec2 uv = vUv;
	#else
		vec2 uv = ( uvTransform * vec3( gl_PointCoord.x, 1.0 - gl_PointCoord.y, 1 ) ).xy;
	#endif
#endif
#ifdef USE_MAP
	diffuseColor *= texture2D( map, uv );
#endif
#ifdef USE_ALPHAMAP
	diffuseColor.a *= texture2D( alphaMap, uv ).g;
#endif`,map_particle_pars_fragment:`#if defined( USE_POINTS_UV )
	varying vec2 vUv;
#else
	#if defined( USE_MAP ) || defined( USE_ALPHAMAP )
		uniform mat3 uvTransform;
	#endif
#endif
#ifdef USE_MAP
	uniform sampler2D map;
#endif
#ifdef USE_ALPHAMAP
	uniform sampler2D alphaMap;
#endif`,metalnessmap_fragment:`float metalnessFactor = metalness;
#ifdef USE_METALNESSMAP
	vec4 texelMetalness = texture2D( metalnessMap, vMetalnessMapUv );
	metalnessFactor *= texelMetalness.b;
#endif`,metalnessmap_pars_fragment:`#ifdef USE_METALNESSMAP
	uniform sampler2D metalnessMap;
#endif`,morphinstance_vertex:`#ifdef USE_INSTANCING_MORPH
	float morphTargetInfluences[ MORPHTARGETS_COUNT ];
	float morphTargetBaseInfluence = texelFetch( morphTexture, ivec2( 0, gl_InstanceID ), 0 ).r;
	for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {
		morphTargetInfluences[i] =  texelFetch( morphTexture, ivec2( i + 1, gl_InstanceID ), 0 ).r;
	}
#endif`,morphcolor_vertex:`#if defined( USE_MORPHCOLORS )
	vColor *= morphTargetBaseInfluence;
	for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {
		#if defined( USE_COLOR_ALPHA )
			if ( morphTargetInfluences[ i ] != 0.0 ) vColor += getMorph( gl_VertexID, i, 2 ) * morphTargetInfluences[ i ];
		#elif defined( USE_COLOR )
			if ( morphTargetInfluences[ i ] != 0.0 ) vColor += getMorph( gl_VertexID, i, 2 ).rgb * morphTargetInfluences[ i ];
		#endif
	}
#endif`,morphnormal_vertex:`#ifdef USE_MORPHNORMALS
	objectNormal *= morphTargetBaseInfluence;
	for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {
		if ( morphTargetInfluences[ i ] != 0.0 ) objectNormal += getMorph( gl_VertexID, i, 1 ).xyz * morphTargetInfluences[ i ];
	}
#endif`,morphtarget_pars_vertex:`#ifdef USE_MORPHTARGETS
	#ifndef USE_INSTANCING_MORPH
		uniform float morphTargetBaseInfluence;
		uniform float morphTargetInfluences[ MORPHTARGETS_COUNT ];
	#endif
	uniform sampler2DArray morphTargetsTexture;
	uniform ivec2 morphTargetsTextureSize;
	vec4 getMorph( const in int vertexIndex, const in int morphTargetIndex, const in int offset ) {
		int texelIndex = vertexIndex * MORPHTARGETS_TEXTURE_STRIDE + offset;
		int y = texelIndex / morphTargetsTextureSize.x;
		int x = texelIndex - y * morphTargetsTextureSize.x;
		ivec3 morphUV = ivec3( x, y, morphTargetIndex );
		return texelFetch( morphTargetsTexture, morphUV, 0 );
	}
#endif`,morphtarget_vertex:`#ifdef USE_MORPHTARGETS
	transformed *= morphTargetBaseInfluence;
	for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {
		if ( morphTargetInfluences[ i ] != 0.0 ) transformed += getMorph( gl_VertexID, i, 0 ).xyz * morphTargetInfluences[ i ];
	}
#endif`,normal_fragment_begin:`float faceDirection = gl_FrontFacing ? 1.0 : - 1.0;
#ifdef FLAT_SHADED
	vec3 fdx = dFdx( vViewPosition );
	vec3 fdy = dFdy( vViewPosition );
	vec3 normal = normalize( cross( fdx, fdy ) );
#else
	vec3 normal = normalize( vNormal );
	#ifdef DOUBLE_SIDED
		normal *= faceDirection;
	#endif
#endif
#if defined( USE_NORMALMAP_TANGENTSPACE ) || defined( USE_CLEARCOAT_NORMALMAP ) || defined( USE_ANISOTROPY )
	#ifdef USE_TANGENT
		mat3 tbn = mat3( normalize( vTangent ), normalize( vBitangent ), normal );
	#else
		mat3 tbn = getTangentFrame( - vViewPosition, normal,
		#if defined( USE_NORMALMAP )
			vNormalMapUv
		#elif defined( USE_CLEARCOAT_NORMALMAP )
			vClearcoatNormalMapUv
		#else
			vUv
		#endif
		);
	#endif
	#if defined( DOUBLE_SIDED ) && ! defined( FLAT_SHADED )
		tbn[0] *= faceDirection;
		tbn[1] *= faceDirection;
	#endif
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	#ifdef USE_TANGENT
		mat3 tbn2 = mat3( normalize( vTangent ), normalize( vBitangent ), normal );
	#else
		mat3 tbn2 = getTangentFrame( - vViewPosition, normal, vClearcoatNormalMapUv );
	#endif
	#if defined( DOUBLE_SIDED ) && ! defined( FLAT_SHADED )
		tbn2[0] *= faceDirection;
		tbn2[1] *= faceDirection;
	#endif
#endif
vec3 nonPerturbedNormal = normal;`,normal_fragment_maps:`#ifdef USE_NORMALMAP_OBJECTSPACE
	normal = texture2D( normalMap, vNormalMapUv ).xyz * 2.0 - 1.0;
	#ifdef FLIP_SIDED
		normal = - normal;
	#endif
	#ifdef DOUBLE_SIDED
		normal = normal * faceDirection;
	#endif
	normal = normalize( normalMatrix * normal );
#elif defined( USE_NORMALMAP_TANGENTSPACE )
	vec3 mapN = texture2D( normalMap, vNormalMapUv ).xyz * 2.0 - 1.0;
	mapN.xy *= normalScale;
	normal = normalize( tbn * mapN );
#elif defined( USE_BUMPMAP )
	normal = perturbNormalArb( - vViewPosition, normal, dHdxy_fwd(), faceDirection );
#endif`,normal_pars_fragment:`#ifndef FLAT_SHADED
	varying vec3 vNormal;
	#ifdef USE_TANGENT
		varying vec3 vTangent;
		varying vec3 vBitangent;
	#endif
#endif`,normal_pars_vertex:`#ifndef FLAT_SHADED
	varying vec3 vNormal;
	#ifdef USE_TANGENT
		varying vec3 vTangent;
		varying vec3 vBitangent;
	#endif
#endif`,normal_vertex:`#ifndef FLAT_SHADED
	vNormal = normalize( transformedNormal );
	#ifdef USE_TANGENT
		vTangent = normalize( transformedTangent );
		vBitangent = normalize( cross( vNormal, vTangent ) * tangent.w );
	#endif
#endif`,normalmap_pars_fragment:`#ifdef USE_NORMALMAP
	uniform sampler2D normalMap;
	uniform vec2 normalScale;
#endif
#ifdef USE_NORMALMAP_OBJECTSPACE
	uniform mat3 normalMatrix;
#endif
#if ! defined ( USE_TANGENT ) && ( defined ( USE_NORMALMAP_TANGENTSPACE ) || defined ( USE_CLEARCOAT_NORMALMAP ) || defined( USE_ANISOTROPY ) )
	mat3 getTangentFrame( vec3 eye_pos, vec3 surf_norm, vec2 uv ) {
		vec3 q0 = dFdx( eye_pos.xyz );
		vec3 q1 = dFdy( eye_pos.xyz );
		vec2 st0 = dFdx( uv.st );
		vec2 st1 = dFdy( uv.st );
		vec3 N = surf_norm;
		vec3 q1perp = cross( q1, N );
		vec3 q0perp = cross( N, q0 );
		vec3 T = q1perp * st0.x + q0perp * st1.x;
		vec3 B = q1perp * st0.y + q0perp * st1.y;
		float det = max( dot( T, T ), dot( B, B ) );
		float scale = ( det == 0.0 ) ? 0.0 : inversesqrt( det );
		return mat3( T * scale, B * scale, N );
	}
#endif`,clearcoat_normal_fragment_begin:`#ifdef USE_CLEARCOAT
	vec3 clearcoatNormal = nonPerturbedNormal;
#endif`,clearcoat_normal_fragment_maps:`#ifdef USE_CLEARCOAT_NORMALMAP
	vec3 clearcoatMapN = texture2D( clearcoatNormalMap, vClearcoatNormalMapUv ).xyz * 2.0 - 1.0;
	clearcoatMapN.xy *= clearcoatNormalScale;
	clearcoatNormal = normalize( tbn2 * clearcoatMapN );
#endif`,clearcoat_pars_fragment:`#ifdef USE_CLEARCOATMAP
	uniform sampler2D clearcoatMap;
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	uniform sampler2D clearcoatNormalMap;
	uniform vec2 clearcoatNormalScale;
#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP
	uniform sampler2D clearcoatRoughnessMap;
#endif`,iridescence_pars_fragment:`#ifdef USE_IRIDESCENCEMAP
	uniform sampler2D iridescenceMap;
#endif
#ifdef USE_IRIDESCENCE_THICKNESSMAP
	uniform sampler2D iridescenceThicknessMap;
#endif`,opaque_fragment:`#ifdef OPAQUE
diffuseColor.a = 1.0;
#endif
#ifdef USE_TRANSMISSION
diffuseColor.a *= material.transmissionAlpha;
#endif
gl_FragColor = vec4( outgoingLight, diffuseColor.a );`,packing:`vec3 packNormalToRGB( const in vec3 normal ) {
	return normalize( normal ) * 0.5 + 0.5;
}
vec3 unpackRGBToNormal( const in vec3 rgb ) {
	return 2.0 * rgb.xyz - 1.0;
}
const float PackUpscale = 256. / 255.;const float UnpackDownscale = 255. / 256.;const float ShiftRight8 = 1. / 256.;
const float Inv255 = 1. / 255.;
const vec4 PackFactors = vec4( 1.0, 256.0, 256.0 * 256.0, 256.0 * 256.0 * 256.0 );
const vec2 UnpackFactors2 = vec2( UnpackDownscale, 1.0 / PackFactors.g );
const vec3 UnpackFactors3 = vec3( UnpackDownscale / PackFactors.rg, 1.0 / PackFactors.b );
const vec4 UnpackFactors4 = vec4( UnpackDownscale / PackFactors.rgb, 1.0 / PackFactors.a );
vec4 packDepthToRGBA( const in float v ) {
	if( v <= 0.0 )
		return vec4( 0., 0., 0., 0. );
	if( v >= 1.0 )
		return vec4( 1., 1., 1., 1. );
	float vuf;
	float af = modf( v * PackFactors.a, vuf );
	float bf = modf( vuf * ShiftRight8, vuf );
	float gf = modf( vuf * ShiftRight8, vuf );
	return vec4( vuf * Inv255, gf * PackUpscale, bf * PackUpscale, af );
}
vec3 packDepthToRGB( const in float v ) {
	if( v <= 0.0 )
		return vec3( 0., 0., 0. );
	if( v >= 1.0 )
		return vec3( 1., 1., 1. );
	float vuf;
	float bf = modf( v * PackFactors.b, vuf );
	float gf = modf( vuf * ShiftRight8, vuf );
	return vec3( vuf * Inv255, gf * PackUpscale, bf );
}
vec2 packDepthToRG( const in float v ) {
	if( v <= 0.0 )
		return vec2( 0., 0. );
	if( v >= 1.0 )
		return vec2( 1., 1. );
	float vuf;
	float gf = modf( v * 256., vuf );
	return vec2( vuf * Inv255, gf );
}
float unpackRGBAToDepth( const in vec4 v ) {
	return dot( v, UnpackFactors4 );
}
float unpackRGBToDepth( const in vec3 v ) {
	return dot( v, UnpackFactors3 );
}
float unpackRGToDepth( const in vec2 v ) {
	return v.r * UnpackFactors2.r + v.g * UnpackFactors2.g;
}
vec4 pack2HalfToRGBA( const in vec2 v ) {
	vec4 r = vec4( v.x, fract( v.x * 255.0 ), v.y, fract( v.y * 255.0 ) );
	return vec4( r.x - r.y / 255.0, r.y, r.z - r.w / 255.0, r.w );
}
vec2 unpackRGBATo2Half( const in vec4 v ) {
	return vec2( v.x + ( v.y / 255.0 ), v.z + ( v.w / 255.0 ) );
}
float viewZToOrthographicDepth( const in float viewZ, const in float near, const in float far ) {
	return ( viewZ + near ) / ( near - far );
}
float orthographicDepthToViewZ( const in float depth, const in float near, const in float far ) {
	return depth * ( near - far ) - near;
}
float viewZToPerspectiveDepth( const in float viewZ, const in float near, const in float far ) {
	return ( ( near + viewZ ) * far ) / ( ( far - near ) * viewZ );
}
float perspectiveDepthToViewZ( const in float depth, const in float near, const in float far ) {
	return ( near * far ) / ( ( far - near ) * depth - far );
}`,premultiplied_alpha_fragment:`#ifdef PREMULTIPLIED_ALPHA
	gl_FragColor.rgb *= gl_FragColor.a;
#endif`,project_vertex:`vec4 mvPosition = vec4( transformed, 1.0 );
#ifdef USE_BATCHING
	mvPosition = batchingMatrix * mvPosition;
#endif
#ifdef USE_INSTANCING
	mvPosition = instanceMatrix * mvPosition;
#endif
mvPosition = modelViewMatrix * mvPosition;
gl_Position = projectionMatrix * mvPosition;`,dithering_fragment:`#ifdef DITHERING
	gl_FragColor.rgb = dithering( gl_FragColor.rgb );
#endif`,dithering_pars_fragment:`#ifdef DITHERING
	vec3 dithering( vec3 color ) {
		float grid_position = rand( gl_FragCoord.xy );
		vec3 dither_shift_RGB = vec3( 0.25 / 255.0, -0.25 / 255.0, 0.25 / 255.0 );
		dither_shift_RGB = mix( 2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position );
		return color + dither_shift_RGB;
	}
#endif`,roughnessmap_fragment:`float roughnessFactor = roughness;
#ifdef USE_ROUGHNESSMAP
	vec4 texelRoughness = texture2D( roughnessMap, vRoughnessMapUv );
	roughnessFactor *= texelRoughness.g;
#endif`,roughnessmap_pars_fragment:`#ifdef USE_ROUGHNESSMAP
	uniform sampler2D roughnessMap;
#endif`,shadowmap_pars_fragment:`#if NUM_SPOT_LIGHT_COORDS > 0
	varying vec4 vSpotLightCoord[ NUM_SPOT_LIGHT_COORDS ];
#endif
#if NUM_SPOT_LIGHT_MAPS > 0
	uniform sampler2D spotLightMap[ NUM_SPOT_LIGHT_MAPS ];
#endif
#ifdef USE_SHADOWMAP
	#if NUM_DIR_LIGHT_SHADOWS > 0
		uniform sampler2D directionalShadowMap[ NUM_DIR_LIGHT_SHADOWS ];
		varying vec4 vDirectionalShadowCoord[ NUM_DIR_LIGHT_SHADOWS ];
		struct DirectionalLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
		};
		uniform DirectionalLightShadow directionalLightShadows[ NUM_DIR_LIGHT_SHADOWS ];
	#endif
	#if NUM_SPOT_LIGHT_SHADOWS > 0
		uniform sampler2D spotShadowMap[ NUM_SPOT_LIGHT_SHADOWS ];
		struct SpotLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
		};
		uniform SpotLightShadow spotLightShadows[ NUM_SPOT_LIGHT_SHADOWS ];
	#endif
	#if NUM_POINT_LIGHT_SHADOWS > 0
		uniform sampler2D pointShadowMap[ NUM_POINT_LIGHT_SHADOWS ];
		varying vec4 vPointShadowCoord[ NUM_POINT_LIGHT_SHADOWS ];
		struct PointLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
			float shadowCameraNear;
			float shadowCameraFar;
		};
		uniform PointLightShadow pointLightShadows[ NUM_POINT_LIGHT_SHADOWS ];
	#endif
	float texture2DCompare( sampler2D depths, vec2 uv, float compare ) {
		float depth = unpackRGBAToDepth( texture2D( depths, uv ) );
		#ifdef USE_REVERSED_DEPTH_BUFFER
			return step( depth, compare );
		#else
			return step( compare, depth );
		#endif
	}
	vec2 texture2DDistribution( sampler2D shadow, vec2 uv ) {
		return unpackRGBATo2Half( texture2D( shadow, uv ) );
	}
	float VSMShadow( sampler2D shadow, vec2 uv, float compare ) {
		float occlusion = 1.0;
		vec2 distribution = texture2DDistribution( shadow, uv );
		#ifdef USE_REVERSED_DEPTH_BUFFER
			float hard_shadow = step( distribution.x, compare );
		#else
			float hard_shadow = step( compare, distribution.x );
		#endif
		if ( hard_shadow != 1.0 ) {
			float distance = compare - distribution.x;
			float variance = max( 0.00000, distribution.y * distribution.y );
			float softness_probability = variance / (variance + distance * distance );			softness_probability = clamp( ( softness_probability - 0.3 ) / ( 0.95 - 0.3 ), 0.0, 1.0 );			occlusion = clamp( max( hard_shadow, softness_probability ), 0.0, 1.0 );
		}
		return occlusion;
	}
	float getShadow( sampler2D shadowMap, vec2 shadowMapSize, float shadowIntensity, float shadowBias, float shadowRadius, vec4 shadowCoord ) {
		float shadow = 1.0;
		shadowCoord.xyz /= shadowCoord.w;
		shadowCoord.z += shadowBias;
		bool inFrustum = shadowCoord.x >= 0.0 && shadowCoord.x <= 1.0 && shadowCoord.y >= 0.0 && shadowCoord.y <= 1.0;
		bool frustumTest = inFrustum && shadowCoord.z <= 1.0;
		if ( frustumTest ) {
		#if defined( SHADOWMAP_TYPE_PCF )
			vec2 texelSize = vec2( 1.0 ) / shadowMapSize;
			float dx0 = - texelSize.x * shadowRadius;
			float dy0 = - texelSize.y * shadowRadius;
			float dx1 = + texelSize.x * shadowRadius;
			float dy1 = + texelSize.y * shadowRadius;
			float dx2 = dx0 / 2.0;
			float dy2 = dy0 / 2.0;
			float dx3 = dx1 / 2.0;
			float dy3 = dy1 / 2.0;
			shadow = (
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx0, dy0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( 0.0, dy0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx1, dy0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx2, dy2 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( 0.0, dy2 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx3, dy2 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx0, 0.0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx2, 0.0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy, shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx3, 0.0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx1, 0.0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx2, dy3 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( 0.0, dy3 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx3, dy3 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx0, dy1 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( 0.0, dy1 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx1, dy1 ), shadowCoord.z )
			) * ( 1.0 / 17.0 );
		#elif defined( SHADOWMAP_TYPE_PCF_SOFT )
			vec2 texelSize = vec2( 1.0 ) / shadowMapSize;
			float dx = texelSize.x;
			float dy = texelSize.y;
			vec2 uv = shadowCoord.xy;
			vec2 f = fract( uv * shadowMapSize + 0.5 );
			uv -= f * texelSize;
			shadow = (
				texture2DCompare( shadowMap, uv, shadowCoord.z ) +
				texture2DCompare( shadowMap, uv + vec2( dx, 0.0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, uv + vec2( 0.0, dy ), shadowCoord.z ) +
				texture2DCompare( shadowMap, uv + texelSize, shadowCoord.z ) +
				mix( texture2DCompare( shadowMap, uv + vec2( -dx, 0.0 ), shadowCoord.z ),
					 texture2DCompare( shadowMap, uv + vec2( 2.0 * dx, 0.0 ), shadowCoord.z ),
					 f.x ) +
				mix( texture2DCompare( shadowMap, uv + vec2( -dx, dy ), shadowCoord.z ),
					 texture2DCompare( shadowMap, uv + vec2( 2.0 * dx, dy ), shadowCoord.z ),
					 f.x ) +
				mix( texture2DCompare( shadowMap, uv + vec2( 0.0, -dy ), shadowCoord.z ),
					 texture2DCompare( shadowMap, uv + vec2( 0.0, 2.0 * dy ), shadowCoord.z ),
					 f.y ) +
				mix( texture2DCompare( shadowMap, uv + vec2( dx, -dy ), shadowCoord.z ),
					 texture2DCompare( shadowMap, uv + vec2( dx, 2.0 * dy ), shadowCoord.z ),
					 f.y ) +
				mix( mix( texture2DCompare( shadowMap, uv + vec2( -dx, -dy ), shadowCoord.z ),
						  texture2DCompare( shadowMap, uv + vec2( 2.0 * dx, -dy ), shadowCoord.z ),
						  f.x ),
					 mix( texture2DCompare( shadowMap, uv + vec2( -dx, 2.0 * dy ), shadowCoord.z ),
						  texture2DCompare( shadowMap, uv + vec2( 2.0 * dx, 2.0 * dy ), shadowCoord.z ),
						  f.x ),
					 f.y )
			) * ( 1.0 / 9.0 );
		#elif defined( SHADOWMAP_TYPE_VSM )
			shadow = VSMShadow( shadowMap, shadowCoord.xy, shadowCoord.z );
		#else
			shadow = texture2DCompare( shadowMap, shadowCoord.xy, shadowCoord.z );
		#endif
		}
		return mix( 1.0, shadow, shadowIntensity );
	}
	vec2 cubeToUV( vec3 v, float texelSizeY ) {
		vec3 absV = abs( v );
		float scaleToCube = 1.0 / max( absV.x, max( absV.y, absV.z ) );
		absV *= scaleToCube;
		v *= scaleToCube * ( 1.0 - 2.0 * texelSizeY );
		vec2 planar = v.xy;
		float almostATexel = 1.5 * texelSizeY;
		float almostOne = 1.0 - almostATexel;
		if ( absV.z >= almostOne ) {
			if ( v.z > 0.0 )
				planar.x = 4.0 - v.x;
		} else if ( absV.x >= almostOne ) {
			float signX = sign( v.x );
			planar.x = v.z * signX + 2.0 * signX;
		} else if ( absV.y >= almostOne ) {
			float signY = sign( v.y );
			planar.x = v.x + 2.0 * signY + 2.0;
			planar.y = v.z * signY - 2.0;
		}
		return vec2( 0.125, 0.25 ) * planar + vec2( 0.375, 0.75 );
	}
	float getPointShadow( sampler2D shadowMap, vec2 shadowMapSize, float shadowIntensity, float shadowBias, float shadowRadius, vec4 shadowCoord, float shadowCameraNear, float shadowCameraFar ) {
		float shadow = 1.0;
		vec3 lightToPosition = shadowCoord.xyz;
		
		float lightToPositionLength = length( lightToPosition );
		if ( lightToPositionLength - shadowCameraFar <= 0.0 && lightToPositionLength - shadowCameraNear >= 0.0 ) {
			float dp = ( lightToPositionLength - shadowCameraNear ) / ( shadowCameraFar - shadowCameraNear );			dp += shadowBias;
			vec3 bd3D = normalize( lightToPosition );
			vec2 texelSize = vec2( 1.0 ) / ( shadowMapSize * vec2( 4.0, 2.0 ) );
			#if defined( SHADOWMAP_TYPE_PCF ) || defined( SHADOWMAP_TYPE_PCF_SOFT ) || defined( SHADOWMAP_TYPE_VSM )
				vec2 offset = vec2( - 1, 1 ) * shadowRadius * texelSize.y;
				shadow = (
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.xyy, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.yyy, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.xyx, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.yyx, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.xxy, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.yxy, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.xxx, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.yxx, texelSize.y ), dp )
				) * ( 1.0 / 9.0 );
			#else
				shadow = texture2DCompare( shadowMap, cubeToUV( bd3D, texelSize.y ), dp );
			#endif
		}
		return mix( 1.0, shadow, shadowIntensity );
	}
#endif`,shadowmap_pars_vertex:`#if NUM_SPOT_LIGHT_COORDS > 0
	uniform mat4 spotLightMatrix[ NUM_SPOT_LIGHT_COORDS ];
	varying vec4 vSpotLightCoord[ NUM_SPOT_LIGHT_COORDS ];
#endif
#ifdef USE_SHADOWMAP
	#if NUM_DIR_LIGHT_SHADOWS > 0
		uniform mat4 directionalShadowMatrix[ NUM_DIR_LIGHT_SHADOWS ];
		varying vec4 vDirectionalShadowCoord[ NUM_DIR_LIGHT_SHADOWS ];
		struct DirectionalLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
		};
		uniform DirectionalLightShadow directionalLightShadows[ NUM_DIR_LIGHT_SHADOWS ];
	#endif
	#if NUM_SPOT_LIGHT_SHADOWS > 0
		struct SpotLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
		};
		uniform SpotLightShadow spotLightShadows[ NUM_SPOT_LIGHT_SHADOWS ];
	#endif
	#if NUM_POINT_LIGHT_SHADOWS > 0
		uniform mat4 pointShadowMatrix[ NUM_POINT_LIGHT_SHADOWS ];
		varying vec4 vPointShadowCoord[ NUM_POINT_LIGHT_SHADOWS ];
		struct PointLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
			float shadowCameraNear;
			float shadowCameraFar;
		};
		uniform PointLightShadow pointLightShadows[ NUM_POINT_LIGHT_SHADOWS ];
	#endif
#endif`,shadowmap_vertex:`#if ( defined( USE_SHADOWMAP ) && ( NUM_DIR_LIGHT_SHADOWS > 0 || NUM_POINT_LIGHT_SHADOWS > 0 ) ) || ( NUM_SPOT_LIGHT_COORDS > 0 )
	vec3 shadowWorldNormal = inverseTransformDirection( transformedNormal, viewMatrix );
	vec4 shadowWorldPosition;
#endif
#if defined( USE_SHADOWMAP )
	#if NUM_DIR_LIGHT_SHADOWS > 0
		#pragma unroll_loop_start
		for ( int i = 0; i < NUM_DIR_LIGHT_SHADOWS; i ++ ) {
			shadowWorldPosition = worldPosition + vec4( shadowWorldNormal * directionalLightShadows[ i ].shadowNormalBias, 0 );
			vDirectionalShadowCoord[ i ] = directionalShadowMatrix[ i ] * shadowWorldPosition;
		}
		#pragma unroll_loop_end
	#endif
	#if NUM_POINT_LIGHT_SHADOWS > 0
		#pragma unroll_loop_start
		for ( int i = 0; i < NUM_POINT_LIGHT_SHADOWS; i ++ ) {
			shadowWorldPosition = worldPosition + vec4( shadowWorldNormal * pointLightShadows[ i ].shadowNormalBias, 0 );
			vPointShadowCoord[ i ] = pointShadowMatrix[ i ] * shadowWorldPosition;
		}
		#pragma unroll_loop_end
	#endif
#endif
#if NUM_SPOT_LIGHT_COORDS > 0
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_SPOT_LIGHT_COORDS; i ++ ) {
		shadowWorldPosition = worldPosition;
		#if ( defined( USE_SHADOWMAP ) && UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )
			shadowWorldPosition.xyz += shadowWorldNormal * spotLightShadows[ i ].shadowNormalBias;
		#endif
		vSpotLightCoord[ i ] = spotLightMatrix[ i ] * shadowWorldPosition;
	}
	#pragma unroll_loop_end
#endif`,shadowmask_pars_fragment:`float getShadowMask() {
	float shadow = 1.0;
	#ifdef USE_SHADOWMAP
	#if NUM_DIR_LIGHT_SHADOWS > 0
	DirectionalLightShadow directionalLight;
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_DIR_LIGHT_SHADOWS; i ++ ) {
		directionalLight = directionalLightShadows[ i ];
		shadow *= receiveShadow ? getShadow( directionalShadowMap[ i ], directionalLight.shadowMapSize, directionalLight.shadowIntensity, directionalLight.shadowBias, directionalLight.shadowRadius, vDirectionalShadowCoord[ i ] ) : 1.0;
	}
	#pragma unroll_loop_end
	#endif
	#if NUM_SPOT_LIGHT_SHADOWS > 0
	SpotLightShadow spotLight;
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_SPOT_LIGHT_SHADOWS; i ++ ) {
		spotLight = spotLightShadows[ i ];
		shadow *= receiveShadow ? getShadow( spotShadowMap[ i ], spotLight.shadowMapSize, spotLight.shadowIntensity, spotLight.shadowBias, spotLight.shadowRadius, vSpotLightCoord[ i ] ) : 1.0;
	}
	#pragma unroll_loop_end
	#endif
	#if NUM_POINT_LIGHT_SHADOWS > 0
	PointLightShadow pointLight;
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_POINT_LIGHT_SHADOWS; i ++ ) {
		pointLight = pointLightShadows[ i ];
		shadow *= receiveShadow ? getPointShadow( pointShadowMap[ i ], pointLight.shadowMapSize, pointLight.shadowIntensity, pointLight.shadowBias, pointLight.shadowRadius, vPointShadowCoord[ i ], pointLight.shadowCameraNear, pointLight.shadowCameraFar ) : 1.0;
	}
	#pragma unroll_loop_end
	#endif
	#endif
	return shadow;
}`,skinbase_vertex:`#ifdef USE_SKINNING
	mat4 boneMatX = getBoneMatrix( skinIndex.x );
	mat4 boneMatY = getBoneMatrix( skinIndex.y );
	mat4 boneMatZ = getBoneMatrix( skinIndex.z );
	mat4 boneMatW = getBoneMatrix( skinIndex.w );
#endif`,skinning_pars_vertex:`#ifdef USE_SKINNING
	uniform mat4 bindMatrix;
	uniform mat4 bindMatrixInverse;
	uniform highp sampler2D boneTexture;
	mat4 getBoneMatrix( const in float i ) {
		int size = textureSize( boneTexture, 0 ).x;
		int j = int( i ) * 4;
		int x = j % size;
		int y = j / size;
		vec4 v1 = texelFetch( boneTexture, ivec2( x, y ), 0 );
		vec4 v2 = texelFetch( boneTexture, ivec2( x + 1, y ), 0 );
		vec4 v3 = texelFetch( boneTexture, ivec2( x + 2, y ), 0 );
		vec4 v4 = texelFetch( boneTexture, ivec2( x + 3, y ), 0 );
		return mat4( v1, v2, v3, v4 );
	}
#endif`,skinning_vertex:`#ifdef USE_SKINNING
	vec4 skinVertex = bindMatrix * vec4( transformed, 1.0 );
	vec4 skinned = vec4( 0.0 );
	skinned += boneMatX * skinVertex * skinWeight.x;
	skinned += boneMatY * skinVertex * skinWeight.y;
	skinned += boneMatZ * skinVertex * skinWeight.z;
	skinned += boneMatW * skinVertex * skinWeight.w;
	transformed = ( bindMatrixInverse * skinned ).xyz;
#endif`,skinnormal_vertex:`#ifdef USE_SKINNING
	mat4 skinMatrix = mat4( 0.0 );
	skinMatrix += skinWeight.x * boneMatX;
	skinMatrix += skinWeight.y * boneMatY;
	skinMatrix += skinWeight.z * boneMatZ;
	skinMatrix += skinWeight.w * boneMatW;
	skinMatrix = bindMatrixInverse * skinMatrix * bindMatrix;
	objectNormal = vec4( skinMatrix * vec4( objectNormal, 0.0 ) ).xyz;
	#ifdef USE_TANGENT
		objectTangent = vec4( skinMatrix * vec4( objectTangent, 0.0 ) ).xyz;
	#endif
#endif`,specularmap_fragment:`float specularStrength;
#ifdef USE_SPECULARMAP
	vec4 texelSpecular = texture2D( specularMap, vSpecularMapUv );
	specularStrength = texelSpecular.r;
#else
	specularStrength = 1.0;
#endif`,specularmap_pars_fragment:`#ifdef USE_SPECULARMAP
	uniform sampler2D specularMap;
#endif`,tonemapping_fragment:`#if defined( TONE_MAPPING )
	gl_FragColor.rgb = toneMapping( gl_FragColor.rgb );
#endif`,tonemapping_pars_fragment:`#ifndef saturate
#define saturate( a ) clamp( a, 0.0, 1.0 )
#endif
uniform float toneMappingExposure;
vec3 LinearToneMapping( vec3 color ) {
	return saturate( toneMappingExposure * color );
}
vec3 ReinhardToneMapping( vec3 color ) {
	color *= toneMappingExposure;
	return saturate( color / ( vec3( 1.0 ) + color ) );
}
vec3 CineonToneMapping( vec3 color ) {
	color *= toneMappingExposure;
	color = max( vec3( 0.0 ), color - 0.004 );
	return pow( ( color * ( 6.2 * color + 0.5 ) ) / ( color * ( 6.2 * color + 1.7 ) + 0.06 ), vec3( 2.2 ) );
}
vec3 RRTAndODTFit( vec3 v ) {
	vec3 a = v * ( v + 0.0245786 ) - 0.000090537;
	vec3 b = v * ( 0.983729 * v + 0.4329510 ) + 0.238081;
	return a / b;
}
vec3 ACESFilmicToneMapping( vec3 color ) {
	const mat3 ACESInputMat = mat3(
		vec3( 0.59719, 0.07600, 0.02840 ),		vec3( 0.35458, 0.90834, 0.13383 ),
		vec3( 0.04823, 0.01566, 0.83777 )
	);
	const mat3 ACESOutputMat = mat3(
		vec3(  1.60475, -0.10208, -0.00327 ),		vec3( -0.53108,  1.10813, -0.07276 ),
		vec3( -0.07367, -0.00605,  1.07602 )
	);
	color *= toneMappingExposure / 0.6;
	color = ACESInputMat * color;
	color = RRTAndODTFit( color );
	color = ACESOutputMat * color;
	return saturate( color );
}
const mat3 LINEAR_REC2020_TO_LINEAR_SRGB = mat3(
	vec3( 1.6605, - 0.1246, - 0.0182 ),
	vec3( - 0.5876, 1.1329, - 0.1006 ),
	vec3( - 0.0728, - 0.0083, 1.1187 )
);
const mat3 LINEAR_SRGB_TO_LINEAR_REC2020 = mat3(
	vec3( 0.6274, 0.0691, 0.0164 ),
	vec3( 0.3293, 0.9195, 0.0880 ),
	vec3( 0.0433, 0.0113, 0.8956 )
);
vec3 agxDefaultContrastApprox( vec3 x ) {
	vec3 x2 = x * x;
	vec3 x4 = x2 * x2;
	return + 15.5 * x4 * x2
		- 40.14 * x4 * x
		+ 31.96 * x4
		- 6.868 * x2 * x
		+ 0.4298 * x2
		+ 0.1191 * x
		- 0.00232;
}
vec3 AgXToneMapping( vec3 color ) {
	const mat3 AgXInsetMatrix = mat3(
		vec3( 0.856627153315983, 0.137318972929847, 0.11189821299995 ),
		vec3( 0.0951212405381588, 0.761241990602591, 0.0767994186031903 ),
		vec3( 0.0482516061458583, 0.101439036467562, 0.811302368396859 )
	);
	const mat3 AgXOutsetMatrix = mat3(
		vec3( 1.1271005818144368, - 0.1413297634984383, - 0.14132976349843826 ),
		vec3( - 0.11060664309660323, 1.157823702216272, - 0.11060664309660294 ),
		vec3( - 0.016493938717834573, - 0.016493938717834257, 1.2519364065950405 )
	);
	const float AgxMinEv = - 12.47393;	const float AgxMaxEv = 4.026069;
	color *= toneMappingExposure;
	color = LINEAR_SRGB_TO_LINEAR_REC2020 * color;
	color = AgXInsetMatrix * color;
	color = max( color, 1e-10 );	color = log2( color );
	color = ( color - AgxMinEv ) / ( AgxMaxEv - AgxMinEv );
	color = clamp( color, 0.0, 1.0 );
	color = agxDefaultContrastApprox( color );
	color = AgXOutsetMatrix * color;
	color = pow( max( vec3( 0.0 ), color ), vec3( 2.2 ) );
	color = LINEAR_REC2020_TO_LINEAR_SRGB * color;
	color = clamp( color, 0.0, 1.0 );
	return color;
}
vec3 NeutralToneMapping( vec3 color ) {
	const float StartCompression = 0.8 - 0.04;
	const float Desaturation = 0.15;
	color *= toneMappingExposure;
	float x = min( color.r, min( color.g, color.b ) );
	float offset = x < 0.08 ? x - 6.25 * x * x : 0.04;
	color -= offset;
	float peak = max( color.r, max( color.g, color.b ) );
	if ( peak < StartCompression ) return color;
	float d = 1. - StartCompression;
	float newPeak = 1. - d * d / ( peak + d - StartCompression );
	color *= newPeak / peak;
	float g = 1. - 1. / ( Desaturation * ( peak - newPeak ) + 1. );
	return mix( color, vec3( newPeak ), g );
}
vec3 CustomToneMapping( vec3 color ) { return color; }`,transmission_fragment:`#ifdef USE_TRANSMISSION
	material.transmission = transmission;
	material.transmissionAlpha = 1.0;
	material.thickness = thickness;
	material.attenuationDistance = attenuationDistance;
	material.attenuationColor = attenuationColor;
	#ifdef USE_TRANSMISSIONMAP
		material.transmission *= texture2D( transmissionMap, vTransmissionMapUv ).r;
	#endif
	#ifdef USE_THICKNESSMAP
		material.thickness *= texture2D( thicknessMap, vThicknessMapUv ).g;
	#endif
	vec3 pos = vWorldPosition;
	vec3 v = normalize( cameraPosition - pos );
	vec3 n = inverseTransformDirection( normal, viewMatrix );
	vec4 transmitted = getIBLVolumeRefraction(
		n, v, material.roughness, material.diffuseColor, material.specularColor, material.specularF90,
		pos, modelMatrix, viewMatrix, projectionMatrix, material.dispersion, material.ior, material.thickness,
		material.attenuationColor, material.attenuationDistance );
	material.transmissionAlpha = mix( material.transmissionAlpha, transmitted.a, material.transmission );
	totalDiffuse = mix( totalDiffuse, transmitted.rgb, material.transmission );
#endif`,transmission_pars_fragment:`#ifdef USE_TRANSMISSION
	uniform float transmission;
	uniform float thickness;
	uniform float attenuationDistance;
	uniform vec3 attenuationColor;
	#ifdef USE_TRANSMISSIONMAP
		uniform sampler2D transmissionMap;
	#endif
	#ifdef USE_THICKNESSMAP
		uniform sampler2D thicknessMap;
	#endif
	uniform vec2 transmissionSamplerSize;
	uniform sampler2D transmissionSamplerMap;
	uniform mat4 modelMatrix;
	uniform mat4 projectionMatrix;
	varying vec3 vWorldPosition;
	float w0( float a ) {
		return ( 1.0 / 6.0 ) * ( a * ( a * ( - a + 3.0 ) - 3.0 ) + 1.0 );
	}
	float w1( float a ) {
		return ( 1.0 / 6.0 ) * ( a *  a * ( 3.0 * a - 6.0 ) + 4.0 );
	}
	float w2( float a ){
		return ( 1.0 / 6.0 ) * ( a * ( a * ( - 3.0 * a + 3.0 ) + 3.0 ) + 1.0 );
	}
	float w3( float a ) {
		return ( 1.0 / 6.0 ) * ( a * a * a );
	}
	float g0( float a ) {
		return w0( a ) + w1( a );
	}
	float g1( float a ) {
		return w2( a ) + w3( a );
	}
	float h0( float a ) {
		return - 1.0 + w1( a ) / ( w0( a ) + w1( a ) );
	}
	float h1( float a ) {
		return 1.0 + w3( a ) / ( w2( a ) + w3( a ) );
	}
	vec4 bicubic( sampler2D tex, vec2 uv, vec4 texelSize, float lod ) {
		uv = uv * texelSize.zw + 0.5;
		vec2 iuv = floor( uv );
		vec2 fuv = fract( uv );
		float g0x = g0( fuv.x );
		float g1x = g1( fuv.x );
		float h0x = h0( fuv.x );
		float h1x = h1( fuv.x );
		float h0y = h0( fuv.y );
		float h1y = h1( fuv.y );
		vec2 p0 = ( vec2( iuv.x + h0x, iuv.y + h0y ) - 0.5 ) * texelSize.xy;
		vec2 p1 = ( vec2( iuv.x + h1x, iuv.y + h0y ) - 0.5 ) * texelSize.xy;
		vec2 p2 = ( vec2( iuv.x + h0x, iuv.y + h1y ) - 0.5 ) * texelSize.xy;
		vec2 p3 = ( vec2( iuv.x + h1x, iuv.y + h1y ) - 0.5 ) * texelSize.xy;
		return g0( fuv.y ) * ( g0x * textureLod( tex, p0, lod ) + g1x * textureLod( tex, p1, lod ) ) +
			g1( fuv.y ) * ( g0x * textureLod( tex, p2, lod ) + g1x * textureLod( tex, p3, lod ) );
	}
	vec4 textureBicubic( sampler2D sampler, vec2 uv, float lod ) {
		vec2 fLodSize = vec2( textureSize( sampler, int( lod ) ) );
		vec2 cLodSize = vec2( textureSize( sampler, int( lod + 1.0 ) ) );
		vec2 fLodSizeInv = 1.0 / fLodSize;
		vec2 cLodSizeInv = 1.0 / cLodSize;
		vec4 fSample = bicubic( sampler, uv, vec4( fLodSizeInv, fLodSize ), floor( lod ) );
		vec4 cSample = bicubic( sampler, uv, vec4( cLodSizeInv, cLodSize ), ceil( lod ) );
		return mix( fSample, cSample, fract( lod ) );
	}
	vec3 getVolumeTransmissionRay( const in vec3 n, const in vec3 v, const in float thickness, const in float ior, const in mat4 modelMatrix ) {
		vec3 refractionVector = refract( - v, normalize( n ), 1.0 / ior );
		vec3 modelScale;
		modelScale.x = length( vec3( modelMatrix[ 0 ].xyz ) );
		modelScale.y = length( vec3( modelMatrix[ 1 ].xyz ) );
		modelScale.z = length( vec3( modelMatrix[ 2 ].xyz ) );
		return normalize( refractionVector ) * thickness * modelScale;
	}
	float applyIorToRoughness( const in float roughness, const in float ior ) {
		return roughness * clamp( ior * 2.0 - 2.0, 0.0, 1.0 );
	}
	vec4 getTransmissionSample( const in vec2 fragCoord, const in float roughness, const in float ior ) {
		float lod = log2( transmissionSamplerSize.x ) * applyIorToRoughness( roughness, ior );
		return textureBicubic( transmissionSamplerMap, fragCoord.xy, lod );
	}
	vec3 volumeAttenuation( const in float transmissionDistance, const in vec3 attenuationColor, const in float attenuationDistance ) {
		if ( isinf( attenuationDistance ) ) {
			return vec3( 1.0 );
		} else {
			vec3 attenuationCoefficient = -log( attenuationColor ) / attenuationDistance;
			vec3 transmittance = exp( - attenuationCoefficient * transmissionDistance );			return transmittance;
		}
	}
	vec4 getIBLVolumeRefraction( const in vec3 n, const in vec3 v, const in float roughness, const in vec3 diffuseColor,
		const in vec3 specularColor, const in float specularF90, const in vec3 position, const in mat4 modelMatrix,
		const in mat4 viewMatrix, const in mat4 projMatrix, const in float dispersion, const in float ior, const in float thickness,
		const in vec3 attenuationColor, const in float attenuationDistance ) {
		vec4 transmittedLight;
		vec3 transmittance;
		#ifdef USE_DISPERSION
			float halfSpread = ( ior - 1.0 ) * 0.025 * dispersion;
			vec3 iors = vec3( ior - halfSpread, ior, ior + halfSpread );
			for ( int i = 0; i < 3; i ++ ) {
				vec3 transmissionRay = getVolumeTransmissionRay( n, v, thickness, iors[ i ], modelMatrix );
				vec3 refractedRayExit = position + transmissionRay;
				vec4 ndcPos = projMatrix * viewMatrix * vec4( refractedRayExit, 1.0 );
				vec2 refractionCoords = ndcPos.xy / ndcPos.w;
				refractionCoords += 1.0;
				refractionCoords /= 2.0;
				vec4 transmissionSample = getTransmissionSample( refractionCoords, roughness, iors[ i ] );
				transmittedLight[ i ] = transmissionSample[ i ];
				transmittedLight.a += transmissionSample.a;
				transmittance[ i ] = diffuseColor[ i ] * volumeAttenuation( length( transmissionRay ), attenuationColor, attenuationDistance )[ i ];
			}
			transmittedLight.a /= 3.0;
		#else
			vec3 transmissionRay = getVolumeTransmissionRay( n, v, thickness, ior, modelMatrix );
			vec3 refractedRayExit = position + transmissionRay;
			vec4 ndcPos = projMatrix * viewMatrix * vec4( refractedRayExit, 1.0 );
			vec2 refractionCoords = ndcPos.xy / ndcPos.w;
			refractionCoords += 1.0;
			refractionCoords /= 2.0;
			transmittedLight = getTransmissionSample( refractionCoords, roughness, ior );
			transmittance = diffuseColor * volumeAttenuation( length( transmissionRay ), attenuationColor, attenuationDistance );
		#endif
		vec3 attenuatedColor = transmittance * transmittedLight.rgb;
		vec3 F = EnvironmentBRDF( n, v, specularColor, specularF90, roughness );
		float transmittanceFactor = ( transmittance.r + transmittance.g + transmittance.b ) / 3.0;
		return vec4( ( 1.0 - F ) * attenuatedColor, 1.0 - ( 1.0 - transmittedLight.a ) * transmittanceFactor );
	}
#endif`,uv_pars_fragment:`#if defined( USE_UV ) || defined( USE_ANISOTROPY )
	varying vec2 vUv;
#endif
#ifdef USE_MAP
	varying vec2 vMapUv;
#endif
#ifdef USE_ALPHAMAP
	varying vec2 vAlphaMapUv;
#endif
#ifdef USE_LIGHTMAP
	varying vec2 vLightMapUv;
#endif
#ifdef USE_AOMAP
	varying vec2 vAoMapUv;
#endif
#ifdef USE_BUMPMAP
	varying vec2 vBumpMapUv;
#endif
#ifdef USE_NORMALMAP
	varying vec2 vNormalMapUv;
#endif
#ifdef USE_EMISSIVEMAP
	varying vec2 vEmissiveMapUv;
#endif
#ifdef USE_METALNESSMAP
	varying vec2 vMetalnessMapUv;
#endif
#ifdef USE_ROUGHNESSMAP
	varying vec2 vRoughnessMapUv;
#endif
#ifdef USE_ANISOTROPYMAP
	varying vec2 vAnisotropyMapUv;
#endif
#ifdef USE_CLEARCOATMAP
	varying vec2 vClearcoatMapUv;
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	varying vec2 vClearcoatNormalMapUv;
#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP
	varying vec2 vClearcoatRoughnessMapUv;
#endif
#ifdef USE_IRIDESCENCEMAP
	varying vec2 vIridescenceMapUv;
#endif
#ifdef USE_IRIDESCENCE_THICKNESSMAP
	varying vec2 vIridescenceThicknessMapUv;
#endif
#ifdef USE_SHEEN_COLORMAP
	varying vec2 vSheenColorMapUv;
#endif
#ifdef USE_SHEEN_ROUGHNESSMAP
	varying vec2 vSheenRoughnessMapUv;
#endif
#ifdef USE_SPECULARMAP
	varying vec2 vSpecularMapUv;
#endif
#ifdef USE_SPECULAR_COLORMAP
	varying vec2 vSpecularColorMapUv;
#endif
#ifdef USE_SPECULAR_INTENSITYMAP
	varying vec2 vSpecularIntensityMapUv;
#endif
#ifdef USE_TRANSMISSIONMAP
	uniform mat3 transmissionMapTransform;
	varying vec2 vTransmissionMapUv;
#endif
#ifdef USE_THICKNESSMAP
	uniform mat3 thicknessMapTransform;
	varying vec2 vThicknessMapUv;
#endif`,uv_pars_vertex:`#if defined( USE_UV ) || defined( USE_ANISOTROPY )
	varying vec2 vUv;
#endif
#ifdef USE_MAP
	uniform mat3 mapTransform;
	varying vec2 vMapUv;
#endif
#ifdef USE_ALPHAMAP
	uniform mat3 alphaMapTransform;
	varying vec2 vAlphaMapUv;
#endif
#ifdef USE_LIGHTMAP
	uniform mat3 lightMapTransform;
	varying vec2 vLightMapUv;
#endif
#ifdef USE_AOMAP
	uniform mat3 aoMapTransform;
	varying vec2 vAoMapUv;
#endif
#ifdef USE_BUMPMAP
	uniform mat3 bumpMapTransform;
	varying vec2 vBumpMapUv;
#endif
#ifdef USE_NORMALMAP
	uniform mat3 normalMapTransform;
	varying vec2 vNormalMapUv;
#endif
#ifdef USE_DISPLACEMENTMAP
	uniform mat3 displacementMapTransform;
	varying vec2 vDisplacementMapUv;
#endif
#ifdef USE_EMISSIVEMAP
	uniform mat3 emissiveMapTransform;
	varying vec2 vEmissiveMapUv;
#endif
#ifdef USE_METALNESSMAP
	uniform mat3 metalnessMapTransform;
	varying vec2 vMetalnessMapUv;
#endif
#ifdef USE_ROUGHNESSMAP
	uniform mat3 roughnessMapTransform;
	varying vec2 vRoughnessMapUv;
#endif
#ifdef USE_ANISOTROPYMAP
	uniform mat3 anisotropyMapTransform;
	varying vec2 vAnisotropyMapUv;
#endif
#ifdef USE_CLEARCOATMAP
	uniform mat3 clearcoatMapTransform;
	varying vec2 vClearcoatMapUv;
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	uniform mat3 clearcoatNormalMapTransform;
	varying vec2 vClearcoatNormalMapUv;
#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP
	uniform mat3 clearcoatRoughnessMapTransform;
	varying vec2 vClearcoatRoughnessMapUv;
#endif
#ifdef USE_SHEEN_COLORMAP
	uniform mat3 sheenColorMapTransform;
	varying vec2 vSheenColorMapUv;
#endif
#ifdef USE_SHEEN_ROUGHNESSMAP
	uniform mat3 sheenRoughnessMapTransform;
	varying vec2 vSheenRoughnessMapUv;
#endif
#ifdef USE_IRIDESCENCEMAP
	uniform mat3 iridescenceMapTransform;
	varying vec2 vIridescenceMapUv;
#endif
#ifdef USE_IRIDESCENCE_THICKNESSMAP
	uniform mat3 iridescenceThicknessMapTransform;
	varying vec2 vIridescenceThicknessMapUv;
#endif
#ifdef USE_SPECULARMAP
	uniform mat3 specularMapTransform;
	varying vec2 vSpecularMapUv;
#endif
#ifdef USE_SPECULAR_COLORMAP
	uniform mat3 specularColorMapTransform;
	varying vec2 vSpecularColorMapUv;
#endif
#ifdef USE_SPECULAR_INTENSITYMAP
	uniform mat3 specularIntensityMapTransform;
	varying vec2 vSpecularIntensityMapUv;
#endif
#ifdef USE_TRANSMISSIONMAP
	uniform mat3 transmissionMapTransform;
	varying vec2 vTransmissionMapUv;
#endif
#ifdef USE_THICKNESSMAP
	uniform mat3 thicknessMapTransform;
	varying vec2 vThicknessMapUv;
#endif`,uv_vertex:`#if defined( USE_UV ) || defined( USE_ANISOTROPY )
	vUv = vec3( uv, 1 ).xy;
#endif
#ifdef USE_MAP
	vMapUv = ( mapTransform * vec3( MAP_UV, 1 ) ).xy;
#endif
#ifdef USE_ALPHAMAP
	vAlphaMapUv = ( alphaMapTransform * vec3( ALPHAMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_LIGHTMAP
	vLightMapUv = ( lightMapTransform * vec3( LIGHTMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_AOMAP
	vAoMapUv = ( aoMapTransform * vec3( AOMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_BUMPMAP
	vBumpMapUv = ( bumpMapTransform * vec3( BUMPMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_NORMALMAP
	vNormalMapUv = ( normalMapTransform * vec3( NORMALMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_DISPLACEMENTMAP
	vDisplacementMapUv = ( displacementMapTransform * vec3( DISPLACEMENTMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_EMISSIVEMAP
	vEmissiveMapUv = ( emissiveMapTransform * vec3( EMISSIVEMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_METALNESSMAP
	vMetalnessMapUv = ( metalnessMapTransform * vec3( METALNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_ROUGHNESSMAP
	vRoughnessMapUv = ( roughnessMapTransform * vec3( ROUGHNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_ANISOTROPYMAP
	vAnisotropyMapUv = ( anisotropyMapTransform * vec3( ANISOTROPYMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_CLEARCOATMAP
	vClearcoatMapUv = ( clearcoatMapTransform * vec3( CLEARCOATMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	vClearcoatNormalMapUv = ( clearcoatNormalMapTransform * vec3( CLEARCOAT_NORMALMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP
	vClearcoatRoughnessMapUv = ( clearcoatRoughnessMapTransform * vec3( CLEARCOAT_ROUGHNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_IRIDESCENCEMAP
	vIridescenceMapUv = ( iridescenceMapTransform * vec3( IRIDESCENCEMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_IRIDESCENCE_THICKNESSMAP
	vIridescenceThicknessMapUv = ( iridescenceThicknessMapTransform * vec3( IRIDESCENCE_THICKNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SHEEN_COLORMAP
	vSheenColorMapUv = ( sheenColorMapTransform * vec3( SHEEN_COLORMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SHEEN_ROUGHNESSMAP
	vSheenRoughnessMapUv = ( sheenRoughnessMapTransform * vec3( SHEEN_ROUGHNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SPECULARMAP
	vSpecularMapUv = ( specularMapTransform * vec3( SPECULARMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SPECULAR_COLORMAP
	vSpecularColorMapUv = ( specularColorMapTransform * vec3( SPECULAR_COLORMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SPECULAR_INTENSITYMAP
	vSpecularIntensityMapUv = ( specularIntensityMapTransform * vec3( SPECULAR_INTENSITYMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_TRANSMISSIONMAP
	vTransmissionMapUv = ( transmissionMapTransform * vec3( TRANSMISSIONMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_THICKNESSMAP
	vThicknessMapUv = ( thicknessMapTransform * vec3( THICKNESSMAP_UV, 1 ) ).xy;
#endif`,worldpos_vertex:`#if defined( USE_ENVMAP ) || defined( DISTANCE ) || defined ( USE_SHADOWMAP ) || defined ( USE_TRANSMISSION ) || NUM_SPOT_LIGHT_COORDS > 0
	vec4 worldPosition = vec4( transformed, 1.0 );
	#ifdef USE_BATCHING
		worldPosition = batchingMatrix * worldPosition;
	#endif
	#ifdef USE_INSTANCING
		worldPosition = instanceMatrix * worldPosition;
	#endif
	worldPosition = modelMatrix * worldPosition;
#endif`,background_vert:`varying vec2 vUv;
uniform mat3 uvTransform;
void main() {
	vUv = ( uvTransform * vec3( uv, 1 ) ).xy;
	gl_Position = vec4( position.xy, 1.0, 1.0 );
}`,background_frag:`uniform sampler2D t2D;
uniform float backgroundIntensity;
varying vec2 vUv;
void main() {
	vec4 texColor = texture2D( t2D, vUv );
	#ifdef DECODE_VIDEO_TEXTURE
		texColor = vec4( mix( pow( texColor.rgb * 0.9478672986 + vec3( 0.0521327014 ), vec3( 2.4 ) ), texColor.rgb * 0.0773993808, vec3( lessThanEqual( texColor.rgb, vec3( 0.04045 ) ) ) ), texColor.w );
	#endif
	texColor.rgb *= backgroundIntensity;
	gl_FragColor = texColor;
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`,backgroundCube_vert:`varying vec3 vWorldDirection;
#include <common>
void main() {
	vWorldDirection = transformDirection( position, modelMatrix );
	#include <begin_vertex>
	#include <project_vertex>
	gl_Position.z = gl_Position.w;
}`,backgroundCube_frag:`#ifdef ENVMAP_TYPE_CUBE
	uniform samplerCube envMap;
#elif defined( ENVMAP_TYPE_CUBE_UV )
	uniform sampler2D envMap;
#endif
uniform float flipEnvMap;
uniform float backgroundBlurriness;
uniform float backgroundIntensity;
uniform mat3 backgroundRotation;
varying vec3 vWorldDirection;
#include <cube_uv_reflection_fragment>
void main() {
	#ifdef ENVMAP_TYPE_CUBE
		vec4 texColor = textureCube( envMap, backgroundRotation * vec3( flipEnvMap * vWorldDirection.x, vWorldDirection.yz ) );
	#elif defined( ENVMAP_TYPE_CUBE_UV )
		vec4 texColor = textureCubeUV( envMap, backgroundRotation * vWorldDirection, backgroundBlurriness );
	#else
		vec4 texColor = vec4( 0.0, 0.0, 0.0, 1.0 );
	#endif
	texColor.rgb *= backgroundIntensity;
	gl_FragColor = texColor;
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`,cube_vert:`varying vec3 vWorldDirection;
#include <common>
void main() {
	vWorldDirection = transformDirection( position, modelMatrix );
	#include <begin_vertex>
	#include <project_vertex>
	gl_Position.z = gl_Position.w;
}`,cube_frag:`uniform samplerCube tCube;
uniform float tFlip;
uniform float opacity;
varying vec3 vWorldDirection;
void main() {
	vec4 texColor = textureCube( tCube, vec3( tFlip * vWorldDirection.x, vWorldDirection.yz ) );
	gl_FragColor = texColor;
	gl_FragColor.a *= opacity;
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`,depth_vert:`#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
varying vec2 vHighPrecisionZW;
void main() {
	#include <uv_vertex>
	#include <batching_vertex>
	#include <skinbase_vertex>
	#include <morphinstance_vertex>
	#ifdef USE_DISPLACEMENTMAP
		#include <beginnormal_vertex>
		#include <morphnormal_vertex>
		#include <skinnormal_vertex>
	#endif
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vHighPrecisionZW = gl_Position.zw;
}`,depth_frag:`#if DEPTH_PACKING == 3200
	uniform float opacity;
#endif
#include <common>
#include <packing>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
varying vec2 vHighPrecisionZW;
void main() {
	vec4 diffuseColor = vec4( 1.0 );
	#include <clipping_planes_fragment>
	#if DEPTH_PACKING == 3200
		diffuseColor.a = opacity;
	#endif
	#include <map_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <logdepthbuf_fragment>
	#ifdef USE_REVERSED_DEPTH_BUFFER
		float fragCoordZ = vHighPrecisionZW[ 0 ] / vHighPrecisionZW[ 1 ];
	#else
		float fragCoordZ = 0.5 * vHighPrecisionZW[ 0 ] / vHighPrecisionZW[ 1 ] + 0.5;
	#endif
	#if DEPTH_PACKING == 3200
		gl_FragColor = vec4( vec3( 1.0 - fragCoordZ ), opacity );
	#elif DEPTH_PACKING == 3201
		gl_FragColor = packDepthToRGBA( fragCoordZ );
	#elif DEPTH_PACKING == 3202
		gl_FragColor = vec4( packDepthToRGB( fragCoordZ ), 1.0 );
	#elif DEPTH_PACKING == 3203
		gl_FragColor = vec4( packDepthToRG( fragCoordZ ), 0.0, 1.0 );
	#endif
}`,distanceRGBA_vert:`#define DISTANCE
varying vec3 vWorldPosition;
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <batching_vertex>
	#include <skinbase_vertex>
	#include <morphinstance_vertex>
	#ifdef USE_DISPLACEMENTMAP
		#include <beginnormal_vertex>
		#include <morphnormal_vertex>
		#include <skinnormal_vertex>
	#endif
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <worldpos_vertex>
	#include <clipping_planes_vertex>
	vWorldPosition = worldPosition.xyz;
}`,distanceRGBA_frag:`#define DISTANCE
uniform vec3 referencePosition;
uniform float nearDistance;
uniform float farDistance;
varying vec3 vWorldPosition;
#include <common>
#include <packing>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <clipping_planes_pars_fragment>
void main () {
	vec4 diffuseColor = vec4( 1.0 );
	#include <clipping_planes_fragment>
	#include <map_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	float dist = length( vWorldPosition - referencePosition );
	dist = ( dist - nearDistance ) / ( farDistance - nearDistance );
	dist = saturate( dist );
	gl_FragColor = packDepthToRGBA( dist );
}`,equirect_vert:`varying vec3 vWorldDirection;
#include <common>
void main() {
	vWorldDirection = transformDirection( position, modelMatrix );
	#include <begin_vertex>
	#include <project_vertex>
}`,equirect_frag:`uniform sampler2D tEquirect;
varying vec3 vWorldDirection;
#include <common>
void main() {
	vec3 direction = normalize( vWorldDirection );
	vec2 sampleUV = equirectUv( direction );
	gl_FragColor = texture2D( tEquirect, sampleUV );
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`,linedashed_vert:`uniform float scale;
attribute float lineDistance;
varying float vLineDistance;
#include <common>
#include <uv_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	vLineDistance = scale * lineDistance;
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <fog_vertex>
}`,linedashed_frag:`uniform vec3 diffuse;
uniform float opacity;
uniform float dashSize;
uniform float totalSize;
varying float vLineDistance;
#include <common>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <fog_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	if ( mod( vLineDistance, totalSize ) > dashSize ) {
		discard;
	}
	vec3 outgoingLight = vec3( 0.0 );
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	outgoingLight = diffuseColor.rgb;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
}`,meshbasic_vert:`#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <envmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#if defined ( USE_ENVMAP ) || defined ( USE_SKINNING )
		#include <beginnormal_vertex>
		#include <morphnormal_vertex>
		#include <skinbase_vertex>
		#include <skinnormal_vertex>
		#include <defaultnormal_vertex>
	#endif
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <worldpos_vertex>
	#include <envmap_vertex>
	#include <fog_vertex>
}`,meshbasic_frag:`uniform vec3 diffuse;
uniform float opacity;
#ifndef FLAT_SHADED
	varying vec3 vNormal;
#endif
#include <common>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_pars_fragment>
#include <fog_pars_fragment>
#include <specularmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <specularmap_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	#ifdef USE_LIGHTMAP
		vec4 lightMapTexel = texture2D( lightMap, vLightMapUv );
		reflectedLight.indirectDiffuse += lightMapTexel.rgb * lightMapIntensity * RECIPROCAL_PI;
	#else
		reflectedLight.indirectDiffuse += vec3( 1.0 );
	#endif
	#include <aomap_fragment>
	reflectedLight.indirectDiffuse *= diffuseColor.rgb;
	vec3 outgoingLight = reflectedLight.indirectDiffuse;
	#include <envmap_fragment>
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,meshlambert_vert:`#define LAMBERT
varying vec3 vViewPosition;
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <envmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vViewPosition = - mvPosition.xyz;
	#include <worldpos_vertex>
	#include <envmap_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
}`,meshlambert_frag:`#define LAMBERT
uniform vec3 diffuse;
uniform vec3 emissive;
uniform float opacity;
#include <common>
#include <packing>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_pars_fragment>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <lights_lambert_pars_fragment>
#include <shadowmap_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <specularmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive;
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <specularmap_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <emissivemap_fragment>
	#include <lights_lambert_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>
	#include <aomap_fragment>
	vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;
	#include <envmap_fragment>
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,meshmatcap_vert:`#define MATCAP
varying vec3 vViewPosition;
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <color_pars_vertex>
#include <displacementmap_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <fog_vertex>
	vViewPosition = - mvPosition.xyz;
}`,meshmatcap_frag:`#define MATCAP
uniform vec3 diffuse;
uniform float opacity;
uniform sampler2D matcap;
varying vec3 vViewPosition;
#include <common>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <fog_pars_fragment>
#include <normal_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	vec3 viewDir = normalize( vViewPosition );
	vec3 x = normalize( vec3( viewDir.z, 0.0, - viewDir.x ) );
	vec3 y = cross( viewDir, x );
	vec2 uv = vec2( dot( x, normal ), dot( y, normal ) ) * 0.495 + 0.5;
	#ifdef USE_MATCAP
		vec4 matcapColor = texture2D( matcap, uv );
	#else
		vec4 matcapColor = vec4( vec3( mix( 0.2, 0.8, uv.y ) ), 1.0 );
	#endif
	vec3 outgoingLight = diffuseColor.rgb * matcapColor.rgb;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,meshnormal_vert:`#define NORMAL
#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP_TANGENTSPACE )
	varying vec3 vViewPosition;
#endif
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphinstance_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP_TANGENTSPACE )
	vViewPosition = - mvPosition.xyz;
#endif
}`,meshnormal_frag:`#define NORMAL
uniform float opacity;
#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP_TANGENTSPACE )
	varying vec3 vViewPosition;
#endif
#include <packing>
#include <uv_pars_fragment>
#include <normal_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( 0.0, 0.0, 0.0, opacity );
	#include <clipping_planes_fragment>
	#include <logdepthbuf_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	gl_FragColor = vec4( packNormalToRGB( normal ), diffuseColor.a );
	#ifdef OPAQUE
		gl_FragColor.a = 1.0;
	#endif
}`,meshphong_vert:`#define PHONG
varying vec3 vViewPosition;
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <envmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphinstance_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vViewPosition = - mvPosition.xyz;
	#include <worldpos_vertex>
	#include <envmap_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
}`,meshphong_frag:`#define PHONG
uniform vec3 diffuse;
uniform vec3 emissive;
uniform vec3 specular;
uniform float shininess;
uniform float opacity;
#include <common>
#include <packing>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_pars_fragment>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <lights_phong_pars_fragment>
#include <shadowmap_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <specularmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive;
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <specularmap_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <emissivemap_fragment>
	#include <lights_phong_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>
	#include <aomap_fragment>
	vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + reflectedLight.directSpecular + reflectedLight.indirectSpecular + totalEmissiveRadiance;
	#include <envmap_fragment>
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,meshphysical_vert:`#define STANDARD
varying vec3 vViewPosition;
#ifdef USE_TRANSMISSION
	varying vec3 vWorldPosition;
#endif
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vViewPosition = - mvPosition.xyz;
	#include <worldpos_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
#ifdef USE_TRANSMISSION
	vWorldPosition = worldPosition.xyz;
#endif
}`,meshphysical_frag:`#define STANDARD
#ifdef PHYSICAL
	#define IOR
	#define USE_SPECULAR
#endif
uniform vec3 diffuse;
uniform vec3 emissive;
uniform float roughness;
uniform float metalness;
uniform float opacity;
#ifdef IOR
	uniform float ior;
#endif
#ifdef USE_SPECULAR
	uniform float specularIntensity;
	uniform vec3 specularColor;
	#ifdef USE_SPECULAR_COLORMAP
		uniform sampler2D specularColorMap;
	#endif
	#ifdef USE_SPECULAR_INTENSITYMAP
		uniform sampler2D specularIntensityMap;
	#endif
#endif
#ifdef USE_CLEARCOAT
	uniform float clearcoat;
	uniform float clearcoatRoughness;
#endif
#ifdef USE_DISPERSION
	uniform float dispersion;
#endif
#ifdef USE_IRIDESCENCE
	uniform float iridescence;
	uniform float iridescenceIOR;
	uniform float iridescenceThicknessMinimum;
	uniform float iridescenceThicknessMaximum;
#endif
#ifdef USE_SHEEN
	uniform vec3 sheenColor;
	uniform float sheenRoughness;
	#ifdef USE_SHEEN_COLORMAP
		uniform sampler2D sheenColorMap;
	#endif
	#ifdef USE_SHEEN_ROUGHNESSMAP
		uniform sampler2D sheenRoughnessMap;
	#endif
#endif
#ifdef USE_ANISOTROPY
	uniform vec2 anisotropyVector;
	#ifdef USE_ANISOTROPYMAP
		uniform sampler2D anisotropyMap;
	#endif
#endif
varying vec3 vViewPosition;
#include <common>
#include <packing>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <iridescence_fragment>
#include <cube_uv_reflection_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_physical_pars_fragment>
#include <fog_pars_fragment>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <lights_physical_pars_fragment>
#include <transmission_pars_fragment>
#include <shadowmap_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <clearcoat_pars_fragment>
#include <iridescence_pars_fragment>
#include <roughnessmap_pars_fragment>
#include <metalnessmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive;
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <roughnessmap_fragment>
	#include <metalnessmap_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <clearcoat_normal_fragment_begin>
	#include <clearcoat_normal_fragment_maps>
	#include <emissivemap_fragment>
	#include <lights_physical_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>
	#include <aomap_fragment>
	vec3 totalDiffuse = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse;
	vec3 totalSpecular = reflectedLight.directSpecular + reflectedLight.indirectSpecular;
	#include <transmission_fragment>
	vec3 outgoingLight = totalDiffuse + totalSpecular + totalEmissiveRadiance;
	#ifdef USE_SHEEN
		float sheenEnergyComp = 1.0 - 0.157 * max3( material.sheenColor );
		outgoingLight = outgoingLight * sheenEnergyComp + sheenSpecularDirect + sheenSpecularIndirect;
	#endif
	#ifdef USE_CLEARCOAT
		float dotNVcc = saturate( dot( geometryClearcoatNormal, geometryViewDir ) );
		vec3 Fcc = F_Schlick( material.clearcoatF0, material.clearcoatF90, dotNVcc );
		outgoingLight = outgoingLight * ( 1.0 - material.clearcoat * Fcc ) + ( clearcoatSpecularDirect + clearcoatSpecularIndirect ) * material.clearcoat;
	#endif
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,meshtoon_vert:`#define TOON
varying vec3 vViewPosition;
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vViewPosition = - mvPosition.xyz;
	#include <worldpos_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
}`,meshtoon_frag:`#define TOON
uniform vec3 diffuse;
uniform vec3 emissive;
uniform float opacity;
#include <common>
#include <packing>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <gradientmap_pars_fragment>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <lights_toon_pars_fragment>
#include <shadowmap_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive;
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <emissivemap_fragment>
	#include <lights_toon_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>
	#include <aomap_fragment>
	vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,points_vert:`uniform float size;
uniform float scale;
#include <common>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
#ifdef USE_POINTS_UV
	varying vec2 vUv;
	uniform mat3 uvTransform;
#endif
void main() {
	#ifdef USE_POINTS_UV
		vUv = ( uvTransform * vec3( uv, 1 ) ).xy;
	#endif
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <project_vertex>
	gl_PointSize = size;
	#ifdef USE_SIZEATTENUATION
		bool isPerspective = isPerspectiveMatrix( projectionMatrix );
		if ( isPerspective ) gl_PointSize *= ( scale / - mvPosition.z );
	#endif
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <worldpos_vertex>
	#include <fog_vertex>
}`,points_frag:`uniform vec3 diffuse;
uniform float opacity;
#include <common>
#include <color_pars_fragment>
#include <map_particle_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <fog_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	vec3 outgoingLight = vec3( 0.0 );
	#include <logdepthbuf_fragment>
	#include <map_particle_fragment>
	#include <color_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	outgoingLight = diffuseColor.rgb;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
}`,shadow_vert:`#include <common>
#include <batching_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <shadowmap_pars_vertex>
void main() {
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphinstance_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <worldpos_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
}`,shadow_frag:`uniform vec3 color;
uniform float opacity;
#include <common>
#include <packing>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <logdepthbuf_pars_fragment>
#include <shadowmap_pars_fragment>
#include <shadowmask_pars_fragment>
void main() {
	#include <logdepthbuf_fragment>
	gl_FragColor = vec4( color, opacity * ( 1.0 - getShadowMask() ) );
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
}`,sprite_vert:`uniform float rotation;
uniform vec2 center;
#include <common>
#include <uv_pars_vertex>
#include <fog_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	vec4 mvPosition = modelViewMatrix[ 3 ];
	vec2 scale = vec2( length( modelMatrix[ 0 ].xyz ), length( modelMatrix[ 1 ].xyz ) );
	#ifndef USE_SIZEATTENUATION
		bool isPerspective = isPerspectiveMatrix( projectionMatrix );
		if ( isPerspective ) scale *= - mvPosition.z;
	#endif
	vec2 alignedPosition = ( position.xy - ( center - vec2( 0.5 ) ) ) * scale;
	vec2 rotatedPosition;
	rotatedPosition.x = cos( rotation ) * alignedPosition.x - sin( rotation ) * alignedPosition.y;
	rotatedPosition.y = sin( rotation ) * alignedPosition.x + cos( rotation ) * alignedPosition.y;
	mvPosition.xy += rotatedPosition;
	gl_Position = projectionMatrix * mvPosition;
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <fog_vertex>
}`,sprite_frag:`uniform vec3 diffuse;
uniform float opacity;
#include <common>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <fog_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	vec3 outgoingLight = vec3( 0.0 );
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	outgoingLight = diffuseColor.rgb;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
}`},Ae={common:{diffuse:{value:new Ve(16777215)},opacity:{value:1},map:{value:null},mapTransform:{value:new Qe},alphaMap:{value:null},alphaMapTransform:{value:new Qe},alphaTest:{value:0}},specularmap:{specularMap:{value:null},specularMapTransform:{value:new Qe}},envmap:{envMap:{value:null},envMapRotation:{value:new Qe},flipEnvMap:{value:-1},reflectivity:{value:1},ior:{value:1.5},refractionRatio:{value:.98}},aomap:{aoMap:{value:null},aoMapIntensity:{value:1},aoMapTransform:{value:new Qe}},lightmap:{lightMap:{value:null},lightMapIntensity:{value:1},lightMapTransform:{value:new Qe}},bumpmap:{bumpMap:{value:null},bumpMapTransform:{value:new Qe},bumpScale:{value:1}},normalmap:{normalMap:{value:null},normalMapTransform:{value:new Qe},normalScale:{value:new pe(1,1)}},displacementmap:{displacementMap:{value:null},displacementMapTransform:{value:new Qe},displacementScale:{value:1},displacementBias:{value:0}},emissivemap:{emissiveMap:{value:null},emissiveMapTransform:{value:new Qe}},metalnessmap:{metalnessMap:{value:null},metalnessMapTransform:{value:new Qe}},roughnessmap:{roughnessMap:{value:null},roughnessMapTransform:{value:new Qe}},gradientmap:{gradientMap:{value:null}},fog:{fogDensity:{value:25e-5},fogNear:{value:1},fogFar:{value:2e3},fogColor:{value:new Ve(16777215)}},lights:{ambientLightColor:{value:[]},lightProbe:{value:[]},directionalLights:{value:[],properties:{direction:{},color:{}}},directionalLightShadows:{value:[],properties:{shadowIntensity:1,shadowBias:{},shadowNormalBias:{},shadowRadius:{},shadowMapSize:{}}},directionalShadowMap:{value:[]},directionalShadowMatrix:{value:[]},spotLights:{value:[],properties:{color:{},position:{},direction:{},distance:{},coneCos:{},penumbraCos:{},decay:{}}},spotLightShadows:{value:[],properties:{shadowIntensity:1,shadowBias:{},shadowNormalBias:{},shadowRadius:{},shadowMapSize:{}}},spotLightMap:{value:[]},spotShadowMap:{value:[]},spotLightMatrix:{value:[]},pointLights:{value:[],properties:{color:{},position:{},decay:{},distance:{}}},pointLightShadows:{value:[],properties:{shadowIntensity:1,shadowBias:{},shadowNormalBias:{},shadowRadius:{},shadowMapSize:{},shadowCameraNear:{},shadowCameraFar:{}}},pointShadowMap:{value:[]},pointShadowMatrix:{value:[]},hemisphereLights:{value:[],properties:{direction:{},skyColor:{},groundColor:{}}},rectAreaLights:{value:[],properties:{color:{},position:{},width:{},height:{}}},ltc_1:{value:null},ltc_2:{value:null}},points:{diffuse:{value:new Ve(16777215)},opacity:{value:1},size:{value:1},scale:{value:1},map:{value:null},alphaMap:{value:null},alphaMapTransform:{value:new Qe},alphaTest:{value:0},uvTransform:{value:new Qe}},sprite:{diffuse:{value:new Ve(16777215)},opacity:{value:1},center:{value:new pe(.5,.5)},rotation:{value:0},map:{value:null},mapTransform:{value:new Qe},alphaMap:{value:null},alphaMapTransform:{value:new Qe},alphaTest:{value:0}}},hi={basic:{uniforms:ln([Ae.common,Ae.specularmap,Ae.envmap,Ae.aomap,Ae.lightmap,Ae.fog]),vertexShader:rt.meshbasic_vert,fragmentShader:rt.meshbasic_frag},lambert:{uniforms:ln([Ae.common,Ae.specularmap,Ae.envmap,Ae.aomap,Ae.lightmap,Ae.emissivemap,Ae.bumpmap,Ae.normalmap,Ae.displacementmap,Ae.fog,Ae.lights,{emissive:{value:new Ve(0)}}]),vertexShader:rt.meshlambert_vert,fragmentShader:rt.meshlambert_frag},phong:{uniforms:ln([Ae.common,Ae.specularmap,Ae.envmap,Ae.aomap,Ae.lightmap,Ae.emissivemap,Ae.bumpmap,Ae.normalmap,Ae.displacementmap,Ae.fog,Ae.lights,{emissive:{value:new Ve(0)},specular:{value:new Ve(1118481)},shininess:{value:30}}]),vertexShader:rt.meshphong_vert,fragmentShader:rt.meshphong_frag},standard:{uniforms:ln([Ae.common,Ae.envmap,Ae.aomap,Ae.lightmap,Ae.emissivemap,Ae.bumpmap,Ae.normalmap,Ae.displacementmap,Ae.roughnessmap,Ae.metalnessmap,Ae.fog,Ae.lights,{emissive:{value:new Ve(0)},roughness:{value:1},metalness:{value:0},envMapIntensity:{value:1}}]),vertexShader:rt.meshphysical_vert,fragmentShader:rt.meshphysical_frag},toon:{uniforms:ln([Ae.common,Ae.aomap,Ae.lightmap,Ae.emissivemap,Ae.bumpmap,Ae.normalmap,Ae.displacementmap,Ae.gradientmap,Ae.fog,Ae.lights,{emissive:{value:new Ve(0)}}]),vertexShader:rt.meshtoon_vert,fragmentShader:rt.meshtoon_frag},matcap:{uniforms:ln([Ae.common,Ae.bumpmap,Ae.normalmap,Ae.displacementmap,Ae.fog,{matcap:{value:null}}]),vertexShader:rt.meshmatcap_vert,fragmentShader:rt.meshmatcap_frag},points:{uniforms:ln([Ae.points,Ae.fog]),vertexShader:rt.points_vert,fragmentShader:rt.points_frag},dashed:{uniforms:ln([Ae.common,Ae.fog,{scale:{value:1},dashSize:{value:1},totalSize:{value:2}}]),vertexShader:rt.linedashed_vert,fragmentShader:rt.linedashed_frag},depth:{uniforms:ln([Ae.common,Ae.displacementmap]),vertexShader:rt.depth_vert,fragmentShader:rt.depth_frag},normal:{uniforms:ln([Ae.common,Ae.bumpmap,Ae.normalmap,Ae.displacementmap,{opacity:{value:1}}]),vertexShader:rt.meshnormal_vert,fragmentShader:rt.meshnormal_frag},sprite:{uniforms:ln([Ae.sprite,Ae.fog]),vertexShader:rt.sprite_vert,fragmentShader:rt.sprite_frag},background:{uniforms:{uvTransform:{value:new Qe},t2D:{value:null},backgroundIntensity:{value:1}},vertexShader:rt.background_vert,fragmentShader:rt.background_frag},backgroundCube:{uniforms:{envMap:{value:null},flipEnvMap:{value:-1},backgroundBlurriness:{value:0},backgroundIntensity:{value:1},backgroundRotation:{value:new Qe}},vertexShader:rt.backgroundCube_vert,fragmentShader:rt.backgroundCube_frag},cube:{uniforms:{tCube:{value:null},tFlip:{value:-1},opacity:{value:1}},vertexShader:rt.cube_vert,fragmentShader:rt.cube_frag},equirect:{uniforms:{tEquirect:{value:null}},vertexShader:rt.equirect_vert,fragmentShader:rt.equirect_frag},distanceRGBA:{uniforms:ln([Ae.common,Ae.displacementmap,{referencePosition:{value:new E},nearDistance:{value:1},farDistance:{value:1e3}}]),vertexShader:rt.distanceRGBA_vert,fragmentShader:rt.distanceRGBA_frag},shadow:{uniforms:ln([Ae.lights,Ae.fog,{color:{value:new Ve(0)},opacity:{value:1}}]),vertexShader:rt.shadow_vert,fragmentShader:rt.shadow_frag}};hi.physical={uniforms:ln([hi.standard.uniforms,{clearcoat:{value:0},clearcoatMap:{value:null},clearcoatMapTransform:{value:new Qe},clearcoatNormalMap:{value:null},clearcoatNormalMapTransform:{value:new Qe},clearcoatNormalScale:{value:new pe(1,1)},clearcoatRoughness:{value:0},clearcoatRoughnessMap:{value:null},clearcoatRoughnessMapTransform:{value:new Qe},dispersion:{value:0},iridescence:{value:0},iridescenceMap:{value:null},iridescenceMapTransform:{value:new Qe},iridescenceIOR:{value:1.3},iridescenceThicknessMinimum:{value:100},iridescenceThicknessMaximum:{value:400},iridescenceThicknessMap:{value:null},iridescenceThicknessMapTransform:{value:new Qe},sheen:{value:0},sheenColor:{value:new Ve(0)},sheenColorMap:{value:null},sheenColorMapTransform:{value:new Qe},sheenRoughness:{value:1},sheenRoughnessMap:{value:null},sheenRoughnessMapTransform:{value:new Qe},transmission:{value:0},transmissionMap:{value:null},transmissionMapTransform:{value:new Qe},transmissionSamplerSize:{value:new pe},transmissionSamplerMap:{value:null},thickness:{value:0},thicknessMap:{value:null},thicknessMapTransform:{value:new Qe},attenuationDistance:{value:0},attenuationColor:{value:new Ve(0)},specularColor:{value:new Ve(1,1,1)},specularColorMap:{value:null},specularColorMapTransform:{value:new Qe},specularIntensity:{value:1},specularIntensityMap:{value:null},specularIntensityMapTransform:{value:new Qe},anisotropyVector:{value:new pe},anisotropyMap:{value:null},anisotropyMapTransform:{value:new Qe}}]),vertexShader:rt.meshphysical_vert,fragmentShader:rt.meshphysical_frag};var nl={r:0,b:0,g:0},Er=new an,qp=new qe;function Yp(i,e,t,n,r,a,s){let o=new Ve(0),c,l,h=a===!0?0:1,u=null,d=0,p=null;function m(f){let v=f.isScene===!0?f.background:null;return v&&v.isTexture&&(v=(f.backgroundBlurriness>0?t:e).get(v)),v}function g(f,v){f.getRGB(nl,Zc(i)),n.buffers.color.setClear(nl.r,nl.g,nl.b,v,s)}return{getClearColor:function(){return o},setClearColor:function(f,v=1){o.set(f),h=v,g(o,h)},getClearAlpha:function(){return h},setClearAlpha:function(f){h=f,g(o,h)},render:function(f){let v=!1,_=m(f);_===null?g(o,h):_&&_.isColor&&(g(_,1),v=!0);let y=i.xr.getEnvironmentBlendMode();y==="additive"?n.buffers.color.setClear(0,0,0,1,s):y==="alpha-blend"&&n.buffers.color.setClear(0,0,0,0,s),(i.autoClear||v)&&(n.buffers.depth.setTest(!0),n.buffers.depth.setMask(!0),n.buffers.color.setMask(!0),i.clear(i.autoClearColor,i.autoClearDepth,i.autoClearStencil))},addToRenderList:function(f,v){let _=m(v);_&&(_.isCubeTexture||_.mapping===os)?(l===void 0&&(l=new Le(new sn(1,1,1),new Dt({name:"BackgroundCubeMaterial",uniforms:Tr(hi.backgroundCube.uniforms),vertexShader:hi.backgroundCube.vertexShader,fragmentShader:hi.backgroundCube.fragmentShader,side:Xt,depthTest:!1,depthWrite:!1,fog:!1,allowOverride:!1})),l.geometry.deleteAttribute("normal"),l.geometry.deleteAttribute("uv"),l.onBeforeRender=function(y,S,w){this.matrixWorld.copyPosition(w.matrixWorld)},Object.defineProperty(l.material,"envMap",{get:function(){return this.uniforms.envMap.value}}),r.update(l)),Er.copy(v.backgroundRotation),Er.x*=-1,Er.y*=-1,Er.z*=-1,_.isCubeTexture&&_.isRenderTargetTexture===!1&&(Er.y*=-1,Er.z*=-1),l.material.uniforms.envMap.value=_,l.material.uniforms.flipEnvMap.value=_.isCubeTexture&&_.isRenderTargetTexture===!1?-1:1,l.material.uniforms.backgroundBlurriness.value=v.backgroundBlurriness,l.material.uniforms.backgroundIntensity.value=v.backgroundIntensity,l.material.uniforms.backgroundRotation.value.setFromMatrix4(qp.makeRotationFromEuler(Er)),l.material.toneMapped=ht.getTransfer(_.colorSpace)!==dt,u===_&&d===_.version&&p===i.toneMapping||(l.material.needsUpdate=!0,u=_,d=_.version,p=i.toneMapping),l.layers.enableAll(),f.unshift(l,l.geometry,l.material,0,0,null)):_&&_.isTexture&&(c===void 0&&(c=new Le(new on(2,2),new Dt({name:"BackgroundMaterial",uniforms:Tr(hi.background.uniforms),vertexShader:hi.background.vertexShader,fragmentShader:hi.background.fragmentShader,side:oi,depthTest:!1,depthWrite:!1,fog:!1,allowOverride:!1})),c.geometry.deleteAttribute("normal"),Object.defineProperty(c.material,"map",{get:function(){return this.uniforms.t2D.value}}),r.update(c)),c.material.uniforms.t2D.value=_,c.material.uniforms.backgroundIntensity.value=v.backgroundIntensity,c.material.toneMapped=ht.getTransfer(_.colorSpace)!==dt,_.matrixAutoUpdate===!0&&_.updateMatrix(),c.material.uniforms.uvTransform.value.copy(_.matrix),u===_&&d===_.version&&p===i.toneMapping||(c.material.needsUpdate=!0,u=_,d=_.version,p=i.toneMapping),c.layers.enableAll(),f.unshift(c,c.geometry,c.material,0,0,null))},dispose:function(){l!==void 0&&(l.geometry.dispose(),l.material.dispose(),l=void 0),c!==void 0&&(c.geometry.dispose(),c.material.dispose(),c=void 0)}}}function Zp(i,e){let t=i.getParameter(i.MAX_VERTEX_ATTRIBS),n={},r=l(null),a=r,s=!1;function o(v){return i.bindVertexArray(v)}function c(v){return i.deleteVertexArray(v)}function l(v){let _=[],y=[],S=[];for(let w=0;w<t;w++)_[w]=0,y[w]=0,S[w]=0;return{geometry:null,program:null,wireframe:!1,newAttributes:_,enabledAttributes:y,attributeDivisors:S,object:v,attributes:{},index:null}}function h(){let v=a.newAttributes;for(let _=0,y=v.length;_<y;_++)v[_]=0}function u(v){d(v,0)}function d(v,_){let y=a.newAttributes,S=a.enabledAttributes,w=a.attributeDivisors;y[v]=1,S[v]===0&&(i.enableVertexAttribArray(v),S[v]=1),w[v]!==_&&(i.vertexAttribDivisor(v,_),w[v]=_)}function p(){let v=a.newAttributes,_=a.enabledAttributes;for(let y=0,S=_.length;y<S;y++)_[y]!==v[y]&&(i.disableVertexAttribArray(y),_[y]=0)}function m(v,_,y,S,w,R,B){B===!0?i.vertexAttribIPointer(v,_,y,w,R):i.vertexAttribPointer(v,_,y,S,w,R)}function g(){f(),s=!0,a!==r&&(a=r,o(a.object))}function f(){r.geometry=null,r.program=null,r.wireframe=!1}return{setup:function(v,_,y,S,w){let R=!1,B=(function(G,D,J){let K=J.wireframe===!0,V=n[G.id];V===void 0&&(V={},n[G.id]=V);let se=V[D.id];se===void 0&&(se={},V[D.id]=se);let X=se[K];return X===void 0&&(X=l(i.createVertexArray()),se[K]=X),X})(S,y,_);a!==B&&(a=B,o(a.object)),R=(function(G,D,J,K){let V=a.attributes,se=D.attributes,X=0,ee=J.getAttributes();for(let Q in ee)if(ee[Q].location>=0){let me=V[Q],ae=se[Q];if(ae===void 0&&(Q==="instanceMatrix"&&G.instanceMatrix&&(ae=G.instanceMatrix),Q==="instanceColor"&&G.instanceColor&&(ae=G.instanceColor)),me===void 0||me.attribute!==ae||ae&&me.data!==ae.data)return!0;X++}return a.attributesNum!==X||a.index!==K})(v,S,y,w),R&&(function(G,D,J,K){let V={},se=D.attributes,X=0,ee=J.getAttributes();for(let Q in ee)if(ee[Q].location>=0){let me=se[Q];me===void 0&&(Q==="instanceMatrix"&&G.instanceMatrix&&(me=G.instanceMatrix),Q==="instanceColor"&&G.instanceColor&&(me=G.instanceColor));let ae={};ae.attribute=me,me&&me.data&&(ae.data=me.data),V[Q]=ae,X++}a.attributes=V,a.attributesNum=X,a.index=K})(v,S,y,w),w!==null&&e.update(w,i.ELEMENT_ARRAY_BUFFER),(R||s)&&(s=!1,(function(G,D,J,K){h();let V=K.attributes,se=J.getAttributes(),X=D.defaultAttributeValues;for(let ee in se){let Q=se[ee];if(Q.location>=0){let me=V[ee];if(me===void 0&&(ee==="instanceMatrix"&&G.instanceMatrix&&(me=G.instanceMatrix),ee==="instanceColor"&&G.instanceColor&&(me=G.instanceColor)),me!==void 0){let ae=me.normalized,be=me.itemSize,Be=e.get(me);if(Be===void 0)continue;let Ie=Be.buffer,Ne=Be.type,le=Be.bytesPerElement,re=Ne===i.INT||Ne===i.UNSIGNED_INT||me.gpuType===qo;if(me.isInterleavedBufferAttribute){let ne=me.data,Oe=ne.stride,Ge=me.offset;if(ne.isInstancedInterleavedBuffer){for(let T=0;T<Q.locationSize;T++)d(Q.location+T,ne.meshPerAttribute);G.isInstancedMesh!==!0&&K._maxInstanceCount===void 0&&(K._maxInstanceCount=ne.meshPerAttribute*ne.count)}else for(let T=0;T<Q.locationSize;T++)u(Q.location+T);i.bindBuffer(i.ARRAY_BUFFER,Ie);for(let T=0;T<Q.locationSize;T++)m(Q.location+T,be/Q.locationSize,Ne,ae,Oe*le,(Ge+be/Q.locationSize*T)*le,re)}else{if(me.isInstancedBufferAttribute){for(let ne=0;ne<Q.locationSize;ne++)d(Q.location+ne,me.meshPerAttribute);G.isInstancedMesh!==!0&&K._maxInstanceCount===void 0&&(K._maxInstanceCount=me.meshPerAttribute*me.count)}else for(let ne=0;ne<Q.locationSize;ne++)u(Q.location+ne);i.bindBuffer(i.ARRAY_BUFFER,Ie);for(let ne=0;ne<Q.locationSize;ne++)m(Q.location+ne,be/Q.locationSize,Ne,ae,be*le,be/Q.locationSize*ne*le,re)}}else if(X!==void 0){let ae=X[ee];if(ae!==void 0)switch(ae.length){case 2:i.vertexAttrib2fv(Q.location,ae);break;case 3:i.vertexAttrib3fv(Q.location,ae);break;case 4:i.vertexAttrib4fv(Q.location,ae);break;default:i.vertexAttrib1fv(Q.location,ae)}}}}p()})(v,_,y,S),w!==null&&i.bindBuffer(i.ELEMENT_ARRAY_BUFFER,e.get(w).buffer))},reset:g,resetDefaultState:f,dispose:function(){g();for(let v in n){let _=n[v];for(let y in _){let S=_[y];for(let w in S)c(S[w].object),delete S[w];delete _[y]}delete n[v]}},releaseStatesOfGeometry:function(v){if(n[v.id]===void 0)return;let _=n[v.id];for(let y in _){let S=_[y];for(let w in S)c(S[w].object),delete S[w];delete _[y]}delete n[v.id]},releaseStatesOfProgram:function(v){for(let _ in n){let y=n[_];if(y[v.id]===void 0)continue;let S=y[v.id];for(let w in S)c(S[w].object),delete S[w];delete y[v.id]}},initAttributes:h,enableAttribute:u,disableUnusedAttributes:p}}function Jp(i,e,t){let n;function r(a,s,o){o!==0&&(i.drawArraysInstanced(n,a,s,o),t.update(s,n,o))}this.setMode=function(a){n=a},this.render=function(a,s){i.drawArrays(n,a,s),t.update(s,n,1)},this.renderInstances=r,this.renderMultiDraw=function(a,s,o){if(o===0)return;e.get("WEBGL_multi_draw").multiDrawArraysWEBGL(n,a,0,s,0,o);let c=0;for(let l=0;l<o;l++)c+=s[l];t.update(c,n,1)},this.renderMultiDrawInstances=function(a,s,o,c){if(o===0)return;let l=e.get("WEBGL_multi_draw");if(l===null)for(let h=0;h<a.length;h++)r(a[h],s[h],c[h]);else{l.multiDrawArraysInstancedWEBGL(n,a,0,s,0,c,0,o);let h=0;for(let u=0;u<o;u++)h+=s[u]*c[u];t.update(h,n,1)}}}function Kp(i,e,t,n){let r;function a(d){if(d==="highp"){if(i.getShaderPrecisionFormat(i.VERTEX_SHADER,i.HIGH_FLOAT).precision>0&&i.getShaderPrecisionFormat(i.FRAGMENT_SHADER,i.HIGH_FLOAT).precision>0)return"highp";d="mediump"}return d==="mediump"&&i.getShaderPrecisionFormat(i.VERTEX_SHADER,i.MEDIUM_FLOAT).precision>0&&i.getShaderPrecisionFormat(i.FRAGMENT_SHADER,i.MEDIUM_FLOAT).precision>0?"mediump":"lowp"}let s=t.precision!==void 0?t.precision:"highp",o=a(s);o!==s&&(console.warn("THREE.WebGLRenderer:",s,"not supported, using",o,"instead."),s=o);let c=t.logarithmicDepthBuffer===!0,l=t.reversedDepthBuffer===!0&&e.has("EXT_clip_control"),h=i.getParameter(i.MAX_TEXTURE_IMAGE_UNITS),u=i.getParameter(i.MAX_VERTEX_TEXTURE_IMAGE_UNITS);return{isWebGL2:!0,getMaxAnisotropy:function(){if(r!==void 0)return r;if(e.has("EXT_texture_filter_anisotropic")===!0){let d=e.get("EXT_texture_filter_anisotropic");r=i.getParameter(d.MAX_TEXTURE_MAX_ANISOTROPY_EXT)}else r=0;return r},getMaxPrecision:a,textureFormatReadable:function(d){return d===qn||n.convert(d)===i.getParameter(i.IMPLEMENTATION_COLOR_READ_FORMAT)},textureTypeReadable:function(d){let p=d===ha&&(e.has("EXT_color_buffer_half_float")||e.has("EXT_color_buffer_float"));return!(d!==ci&&n.convert(d)!==i.getParameter(i.IMPLEMENTATION_COLOR_READ_TYPE)&&d!==jn&&!p)},precision:s,logarithmicDepthBuffer:c,reversedDepthBuffer:l,maxTextures:h,maxVertexTextures:u,maxTextureSize:i.getParameter(i.MAX_TEXTURE_SIZE),maxCubemapSize:i.getParameter(i.MAX_CUBE_MAP_TEXTURE_SIZE),maxAttributes:i.getParameter(i.MAX_VERTEX_ATTRIBS),maxVertexUniforms:i.getParameter(i.MAX_VERTEX_UNIFORM_VECTORS),maxVaryings:i.getParameter(i.MAX_VARYING_VECTORS),maxFragmentUniforms:i.getParameter(i.MAX_FRAGMENT_UNIFORM_VECTORS),vertexTextures:u>0,maxSamples:i.getParameter(i.MAX_SAMPLES)}}function $p(i){let e=this,t=null,n=0,r=!1,a=!1,s=new ti,o=new Qe,c={value:null,needsUpdate:!1};function l(h,u,d,p){let m=h!==null?h.length:0,g=null;if(m!==0){if(g=c.value,p!==!0||g===null){let f=d+4*m,v=u.matrixWorldInverse;o.getNormalMatrix(v),(g===null||g.length<f)&&(g=new Float32Array(f));for(let _=0,y=d;_!==m;++_,y+=4)s.copy(h[_]).applyMatrix4(v,o),s.normal.toArray(g,y),g[y+3]=s.constant}c.value=g,c.needsUpdate=!0}return e.numPlanes=m,e.numIntersection=0,g}this.uniform=c,this.numPlanes=0,this.numIntersection=0,this.init=function(h,u){let d=h.length!==0||u||n!==0||r;return r=u,n=h.length,d},this.beginShadows=function(){a=!0,l(null)},this.endShadows=function(){a=!1},this.setGlobalState=function(h,u){t=l(h,u,0)},this.setState=function(h,u,d){let p=h.clippingPlanes,m=h.clipIntersection,g=h.clipShadows,f=i.get(h);if(!r||p===null||p.length===0||a&&!g)a?l(null):(function(){c.value!==t&&(c.value=t,c.needsUpdate=n>0),e.numPlanes=n,e.numIntersection=0})();else{let v=a?0:n,_=4*v,y=f.clippingState||null;c.value=y,y=l(p,u,_,d);for(let S=0;S!==_;++S)y[S]=t[S];f.clippingState=y,this.numIntersection=m?this.numPlanes:0,this.numPlanes+=v}}}function Qp(i){let e=new WeakMap;function t(r,a){return a===Wo?r.mapping=la:a===Xo&&(r.mapping=yr),r}function n(r){let a=r.target;a.removeEventListener("dispose",n);let s=e.get(a);s!==void 0&&(e.delete(a),s.dispose())}return{get:function(r){if(r&&r.isTexture){let a=r.mapping;if(a===Wo||a===Xo){if(e.has(r))return t(e.get(r).texture,r.mapping);{let s=r.image;if(s&&s.height>0){let o=new eo(s.height);return o.fromEquirectangularTexture(i,r),e.set(r,o),r.addEventListener("dispose",n),t(o.texture,r.mapping)}return null}}}return r},dispose:function(){e=new WeakMap}}}var ud=[.125,.215,.35,.446,.526,.582],us=20,Qc=new vr,dd=new Ve,eh=null,th=0,nh=0,ih=!1,Ar=(1+Math.sqrt(5))/2,da=1/Ar,pd=[new E(-Ar,da,0),new E(Ar,da,0),new E(-da,0,Ar),new E(da,0,Ar),new E(0,Ar,-da),new E(0,Ar,da),new E(-1,1,-1),new E(1,1,-1),new E(-1,1,1),new E(1,1,1)],ef=new E,fa=class{constructor(e){this._renderer=e,this._pingPongRenderTarget=null,this._lodMax=0,this._cubeSize=0,this._lodPlanes=[],this._sizeLods=[],this._sigmas=[],this._blurMaterial=null,this._cubemapMaterial=null,this._equirectMaterial=null,this._compileMaterial(this._blurMaterial)}fromScene(e,t=0,n=.1,r=100,a={}){let{size:s=256,position:o=ef}=a;eh=this._renderer.getRenderTarget(),th=this._renderer.getActiveCubeFace(),nh=this._renderer.getActiveMipmapLevel(),ih=this._renderer.xr.enabled,this._renderer.xr.enabled=!1,this._setSize(s);let c=this._allocateTargets();return c.depthBuffer=!0,this._sceneToCubeUV(e,n,r,c,o),t>0&&this._blur(c,0,0,t),this._applyPMREM(c),this._cleanup(c),c}fromEquirectangular(e,t=null){return this._fromTexture(e,t)}fromCubemap(e,t=null){return this._fromTexture(e,t)}compileCubemapShader(){this._cubemapMaterial===null&&(this._cubemapMaterial=gd(),this._compileMaterial(this._cubemapMaterial))}compileEquirectangularShader(){this._equirectMaterial===null&&(this._equirectMaterial=md(),this._compileMaterial(this._equirectMaterial))}dispose(){this._dispose(),this._cubemapMaterial!==null&&this._cubemapMaterial.dispose(),this._equirectMaterial!==null&&this._equirectMaterial.dispose()}_setSize(e){this._lodMax=Math.floor(Math.log2(e)),this._cubeSize=Math.pow(2,this._lodMax)}_dispose(){this._blurMaterial!==null&&this._blurMaterial.dispose(),this._pingPongRenderTarget!==null&&this._pingPongRenderTarget.dispose();for(let e=0;e<this._lodPlanes.length;e++)this._lodPlanes[e].dispose()}_cleanup(e){this._renderer.setRenderTarget(eh,th,nh),this._renderer.xr.enabled=ih,e.scissorTest=!1,il(e,0,0,e.width,e.height)}_fromTexture(e,t){e.mapping===la||e.mapping===yr?this._setSize(e.image.length===0?16:e.image[0].width||e.image[0].image.width):this._setSize(e.image.width/4),eh=this._renderer.getRenderTarget(),th=this._renderer.getActiveCubeFace(),nh=this._renderer.getActiveMipmapLevel(),ih=this._renderer.xr.enabled,this._renderer.xr.enabled=!1;let n=t||this._allocateTargets();return this._textureToCubeUV(e,n),this._applyPMREM(n),this._cleanup(n),n}_allocateTargets(){let e=3*Math.max(this._cubeSize,112),t=4*this._cubeSize,n={magFilter:ri,minFilter:ri,generateMipmaps:!1,type:ha,format:qn,colorSpace:pr,depthBuffer:!1},r=fd(e,t,n);if(this._pingPongRenderTarget===null||this._pingPongRenderTarget.width!==e||this._pingPongRenderTarget.height!==t){this._pingPongRenderTarget!==null&&this._dispose(),this._pingPongRenderTarget=fd(e,t,n);let{_lodMax:a}=this;({sizeLods:this._sizeLods,lodPlanes:this._lodPlanes,sigmas:this._sigmas}=(function(s){let o=[],c=[],l=[],h=s,u=s-4+1+ud.length;for(let d=0;d<u;d++){let p=Math.pow(2,h);c.push(p);let m=1/p;d>s-4?m=ud[d-s+4-1]:d===0&&(m=0),l.push(m);let g=1/(p-2),f=-g,v=1+g,_=[f,f,v,f,v,v,f,f,v,v,f,v],y=6,S=6,w=3,R=2,B=1,G=new Float32Array(w*S*y),D=new Float32Array(R*S*y),J=new Float32Array(B*S*y);for(let V=0;V<y;V++){let se=V%3*2/3-1,X=V>2?0:-1,ee=[se,X,0,se+2/3,X,0,se+2/3,X+1,0,se,X,0,se+2/3,X+1,0,se,X+1,0];G.set(ee,w*S*V),D.set(_,R*S*V);let Q=[V,V,V,V,V,V];J.set(Q,B*S*V)}let K=new mt;K.setAttribute("position",new pt(G,w)),K.setAttribute("uv",new pt(D,R)),K.setAttribute("faceIndex",new pt(J,B)),o.push(K),h>4&&h--}return{lodPlanes:o,sizeLods:c,sigmas:l}})(a)),this._blurMaterial=(function(s,o,c){let l=new Float32Array(us),h=new E(0,1,0);return new Dt({name:"SphericalGaussianBlur",defines:{n:us,CUBEUV_TEXEL_WIDTH:1/o,CUBEUV_TEXEL_HEIGHT:1/c,CUBEUV_MAX_MIP:`${s}.0`},uniforms:{envMap:{value:null},samples:{value:1},weights:{value:l},latitudinal:{value:!1},dTheta:{value:0},mipInt:{value:0},poleAxis:{value:h}},vertexShader:ph(),fragmentShader:`

			precision mediump float;
			precision mediump int;

			varying vec3 vOutputDirection;

			uniform sampler2D envMap;
			uniform int samples;
			uniform float weights[ n ];
			uniform bool latitudinal;
			uniform float dTheta;
			uniform float mipInt;
			uniform vec3 poleAxis;

			#define ENVMAP_TYPE_CUBE_UV
			#include <cube_uv_reflection_fragment>

			vec3 getSample( float theta, vec3 axis ) {

				float cosTheta = cos( theta );
				// Rodrigues' axis-angle rotation
				vec3 sampleDirection = vOutputDirection * cosTheta
					+ cross( axis, vOutputDirection ) * sin( theta )
					+ axis * dot( axis, vOutputDirection ) * ( 1.0 - cosTheta );

				return bilinearCubeUV( envMap, sampleDirection, mipInt );

			}

			void main() {

				vec3 axis = latitudinal ? poleAxis : cross( poleAxis, vOutputDirection );

				if ( all( equal( axis, vec3( 0.0 ) ) ) ) {

					axis = vec3( vOutputDirection.z, 0.0, - vOutputDirection.x );

				}

				axis = normalize( axis );

				gl_FragColor = vec4( 0.0, 0.0, 0.0, 1.0 );
				gl_FragColor.rgb += weights[ 0 ] * getSample( 0.0, axis );

				for ( int i = 1; i < n; i++ ) {

					if ( i >= samples ) {

						break;

					}

					float theta = dTheta * float( i );
					gl_FragColor.rgb += weights[ i ] * getSample( -1.0 * theta, axis );
					gl_FragColor.rgb += weights[ i ] * getSample( theta, axis );

				}

			}
		`,blending:li,depthTest:!1,depthWrite:!1})})(a,e,t)}return r}_compileMaterial(e){let t=new Le(this._lodPlanes[0],e);this._renderer.compile(t,Qc)}_sceneToCubeUV(e,t,n,r,a){let s=new rn(90,1,t,n),o=[1,-1,1,1,1,1],c=[1,1,1,-1,-1,-1],l=this._renderer,h=l.autoClear,u=l.toneMapping;l.getClearColor(dd),l.toneMapping=Pi,l.autoClear=!1,l.state.buffers.depth.getReversed()&&(l.setRenderTarget(r),l.clearDepth(),l.setRenderTarget(null));let d=new Ft({name:"PMREM.Background",side:Xt,depthWrite:!1,depthTest:!1}),p=new Le(new sn,d),m=!1,g=e.background;g?g.isColor&&(d.color.copy(g),e.background=null,m=!0):(d.color.copy(dd),m=!0);for(let f=0;f<6;f++){let v=f%3;v===0?(s.up.set(0,o[f],0),s.position.set(a.x,a.y,a.z),s.lookAt(a.x+c[f],a.y,a.z)):v===1?(s.up.set(0,0,o[f]),s.position.set(a.x,a.y,a.z),s.lookAt(a.x,a.y+c[f],a.z)):(s.up.set(0,o[f],0),s.position.set(a.x,a.y,a.z),s.lookAt(a.x,a.y,a.z+c[f]));let _=this._cubeSize;il(r,v*_,f>2?_:0,_,_),l.setRenderTarget(r),m&&l.render(p,s),l.render(e,s)}p.geometry.dispose(),p.material.dispose(),l.toneMapping=u,l.autoClear=h,e.background=g}_textureToCubeUV(e,t){let n=this._renderer,r=e.mapping===la||e.mapping===yr;r?(this._cubemapMaterial===null&&(this._cubemapMaterial=gd()),this._cubemapMaterial.uniforms.flipEnvMap.value=e.isRenderTargetTexture===!1?-1:1):this._equirectMaterial===null&&(this._equirectMaterial=md());let a=r?this._cubemapMaterial:this._equirectMaterial,s=new Le(this._lodPlanes[0],a);a.uniforms.envMap.value=e;let o=this._cubeSize;il(t,0,0,3*o,2*o),n.setRenderTarget(t),n.render(s,Qc)}_applyPMREM(e){let t=this._renderer,n=t.autoClear;t.autoClear=!1;let r=this._lodPlanes.length;for(let a=1;a<r;a++){let s=Math.sqrt(this._sigmas[a]*this._sigmas[a]-this._sigmas[a-1]*this._sigmas[a-1]),o=pd[(r-a-1)%pd.length];this._blur(e,a-1,a,s,o)}t.autoClear=n}_blur(e,t,n,r,a){let s=this._pingPongRenderTarget;this._halfBlur(e,s,t,n,r,"latitudinal",a),this._halfBlur(s,e,n,n,r,"longitudinal",a)}_halfBlur(e,t,n,r,a,s,o){let c=this._renderer,l=this._blurMaterial;s!=="latitudinal"&&s!=="longitudinal"&&console.error("blur direction must be either latitudinal or longitudinal!");let h=new Le(this._lodPlanes[r],l),u=l.uniforms,d=this._sizeLods[n]-1,p=isFinite(a)?Math.PI/(2*d):2*Math.PI/39,m=a/p,g=isFinite(a)?1+Math.floor(3*m):us;g>us&&console.warn(`sigmaRadians, ${a}, is too large and will clip, as it requested ${g} samples when the maximum is set to 20`);let f=[],v=0;for(let S=0;S<us;++S){let w=S/m,R=Math.exp(-w*w/2);f.push(R),S===0?v+=R:S<g&&(v+=2*R)}for(let S=0;S<f.length;S++)f[S]=f[S]/v;u.envMap.value=e.texture,u.samples.value=g,u.weights.value=f,u.latitudinal.value=s==="latitudinal",o&&(u.poleAxis.value=o);let{_lodMax:_}=this;u.dTheta.value=p,u.mipInt.value=_-n;let y=this._sizeLods[r];il(t,3*y*(r>_-4?r-_+4:0),4*(this._cubeSize-y),3*y,2*y),c.setRenderTarget(t),c.render(h,Qc)}};function fd(i,e,t){let n=new yn(i,e,t);return n.texture.mapping=os,n.texture.name="PMREM.cubeUv",n.scissorTest=!0,n}function il(i,e,t,n,r){i.viewport.set(e,t,n,r),i.scissor.set(e,t,n,r)}function md(){return new Dt({name:"EquirectangularToCubeUV",uniforms:{envMap:{value:null}},vertexShader:ph(),fragmentShader:`

			precision mediump float;
			precision mediump int;

			varying vec3 vOutputDirection;

			uniform sampler2D envMap;

			#include <common>

			void main() {

				vec3 outputDirection = normalize( vOutputDirection );
				vec2 uv = equirectUv( outputDirection );

				gl_FragColor = vec4( texture2D ( envMap, uv ).rgb, 1.0 );

			}
		`,blending:li,depthTest:!1,depthWrite:!1})}function gd(){return new Dt({name:"CubemapToCubeUV",uniforms:{envMap:{value:null},flipEnvMap:{value:-1}},vertexShader:ph(),fragmentShader:`

			precision mediump float;
			precision mediump int;

			uniform float flipEnvMap;

			varying vec3 vOutputDirection;

			uniform samplerCube envMap;

			void main() {

				gl_FragColor = textureCube( envMap, vec3( flipEnvMap * vOutputDirection.x, vOutputDirection.yz ) );

			}
		`,blending:li,depthTest:!1,depthWrite:!1})}function ph(){return`

		precision mediump float;
		precision mediump int;

		attribute float faceIndex;

		varying vec3 vOutputDirection;

		// RH coordinate system; PMREM face-indexing convention
		vec3 getDirection( vec2 uv, float face ) {

			uv = 2.0 * uv - 1.0;

			vec3 direction = vec3( uv, 1.0 );

			if ( face == 0.0 ) {

				direction = direction.zyx; // ( 1, v, u ) pos x

			} else if ( face == 1.0 ) {

				direction = direction.xzy;
				direction.xz *= -1.0; // ( -u, 1, -v ) pos y

			} else if ( face == 2.0 ) {

				direction.x *= -1.0; // ( -u, v, 1 ) pos z

			} else if ( face == 3.0 ) {

				direction = direction.zyx;
				direction.xz *= -1.0; // ( -1, v, -u ) neg x

			} else if ( face == 4.0 ) {

				direction = direction.xzy;
				direction.xy *= -1.0; // ( -u, -1, v ) neg y

			} else if ( face == 5.0 ) {

				direction.z *= -1.0; // ( u, v, -1 ) neg z

			}

			return direction;

		}

		void main() {

			vOutputDirection = getDirection( uv, faceIndex );
			gl_Position = vec4( position, 1.0 );

		}
	`}function tf(i){let e=new WeakMap,t=null;function n(r){let a=r.target;a.removeEventListener("dispose",n);let s=e.get(a);s!==void 0&&(e.delete(a),s.dispose())}return{get:function(r){if(r&&r.isTexture){let a=r.mapping,s=a===Wo||a===Xo,o=a===la||a===yr;if(s||o){let c=e.get(r),l=c!==void 0?c.texture.pmremVersion:0;if(r.isRenderTargetTexture&&r.pmremVersion!==l)return t===null&&(t=new fa(i)),c=s?t.fromEquirectangular(r,c):t.fromCubemap(r,c),c.texture.pmremVersion=r.pmremVersion,e.set(r,c),c.texture;if(c!==void 0)return c.texture;{let h=r.image;return s&&h&&h.height>0||o&&h&&(function(u){let d=0,p=6;for(let m=0;m<p;m++)u[m]!==void 0&&d++;return d===p})(h)?(t===null&&(t=new fa(i)),c=s?t.fromEquirectangular(r):t.fromCubemap(r),c.texture.pmremVersion=r.pmremVersion,e.set(r,c),r.addEventListener("dispose",n),c.texture):null}}}return r},dispose:function(){e=new WeakMap,t!==null&&(t.dispose(),t=null)}}}function nf(i){let e={};function t(n){if(e[n]!==void 0)return e[n];let r;switch(n){case"WEBGL_depth_texture":r=i.getExtension("WEBGL_depth_texture")||i.getExtension("MOZ_WEBGL_depth_texture")||i.getExtension("WEBKIT_WEBGL_depth_texture");break;case"EXT_texture_filter_anisotropic":r=i.getExtension("EXT_texture_filter_anisotropic")||i.getExtension("MOZ_EXT_texture_filter_anisotropic")||i.getExtension("WEBKIT_EXT_texture_filter_anisotropic");break;case"WEBGL_compressed_texture_s3tc":r=i.getExtension("WEBGL_compressed_texture_s3tc")||i.getExtension("MOZ_WEBGL_compressed_texture_s3tc")||i.getExtension("WEBKIT_WEBGL_compressed_texture_s3tc");break;case"WEBGL_compressed_texture_pvrtc":r=i.getExtension("WEBGL_compressed_texture_pvrtc")||i.getExtension("WEBKIT_WEBGL_compressed_texture_pvrtc");break;default:r=i.getExtension(n)}return e[n]=r,r}return{has:function(n){return t(n)!==null},init:function(){t("EXT_color_buffer_float"),t("WEBGL_clip_cull_distance"),t("OES_texture_float_linear"),t("EXT_color_buffer_half_float"),t("WEBGL_multisampled_render_to_texture"),t("WEBGL_render_shared_exponent")},get:function(n){let r=t(n);return r===null&&ea("THREE.WebGLRenderer: "+n+" extension not supported."),r}}}function rf(i,e,t,n){let r={},a=new WeakMap;function s(c){let l=c.target;l.index!==null&&e.remove(l.index);for(let u in l.attributes)e.remove(l.attributes[u]);l.removeEventListener("dispose",s),delete r[l.id];let h=a.get(l);h&&(e.remove(h),a.delete(l)),n.releaseStatesOfGeometry(l),l.isInstancedBufferGeometry===!0&&delete l._maxInstanceCount,t.memory.geometries--}function o(c){let l=[],h=c.index,u=c.attributes.position,d=0;if(h!==null){let g=h.array;d=h.version;for(let f=0,v=g.length;f<v;f+=3){let _=g[f+0],y=g[f+1],S=g[f+2];l.push(_,y,y,S,S,_)}}else{if(u===void 0)return;{let g=u.array;d=u.version;for(let f=0,v=g.length/3-1;f<v;f+=3){let _=f+0,y=f+1,S=f+2;l.push(_,y,y,S,S,_)}}}let p=new(Yc(l)?Ga:Ha)(l,1);p.version=d;let m=a.get(c);m&&e.remove(m),a.set(c,p)}return{get:function(c,l){return r[l.id]===!0||(l.addEventListener("dispose",s),r[l.id]=!0,t.memory.geometries++),l},update:function(c){let l=c.attributes;for(let h in l)e.update(l[h],i.ARRAY_BUFFER)},getWireframeAttribute:function(c){let l=a.get(c);if(l){let h=c.index;h!==null&&l.version<h.version&&o(c)}else o(c);return a.get(c)}}}function af(i,e,t){let n,r,a;function s(o,c,l){l!==0&&(i.drawElementsInstanced(n,c,r,o*a,l),t.update(c,n,l))}this.setMode=function(o){n=o},this.setIndex=function(o){r=o.type,a=o.bytesPerElement},this.render=function(o,c){i.drawElements(n,c,r,o*a),t.update(c,n,1)},this.renderInstances=s,this.renderMultiDraw=function(o,c,l){if(l===0)return;e.get("WEBGL_multi_draw").multiDrawElementsWEBGL(n,c,0,r,o,0,l);let h=0;for(let u=0;u<l;u++)h+=c[u];t.update(h,n,1)},this.renderMultiDrawInstances=function(o,c,l,h){if(l===0)return;let u=e.get("WEBGL_multi_draw");if(u===null)for(let d=0;d<o.length;d++)s(o[d]/a,c[d],h[d]);else{u.multiDrawElementsInstancedWEBGL(n,c,0,r,o,0,h,0,l);let d=0;for(let p=0;p<l;p++)d+=c[p]*h[p];t.update(d,n,1)}}}function sf(i){let e={frame:0,calls:0,triangles:0,points:0,lines:0};return{memory:{geometries:0,textures:0},render:e,programs:null,autoReset:!0,reset:function(){e.calls=0,e.triangles=0,e.points=0,e.lines=0},update:function(t,n,r){switch(e.calls++,n){case i.TRIANGLES:e.triangles+=r*(t/3);break;case i.LINES:e.lines+=r*(t/2);break;case i.LINE_STRIP:e.lines+=r*(t-1);break;case i.LINE_LOOP:e.lines+=r*t;break;case i.POINTS:e.points+=r*t;break;default:console.error("THREE.WebGLInfo: Unknown draw mode:",n)}}}}function of(i,e,t){let n=new WeakMap,r=new xt;return{update:function(a,s,o){let c=a.morphTargetInfluences,l=s.morphAttributes.position||s.morphAttributes.normal||s.morphAttributes.color,h=l!==void 0?l.length:0,u=n.get(s);if(u===void 0||u.count!==h){let G=function(){R.dispose(),n.delete(s),s.removeEventListener("dispose",G)};u!==void 0&&u.texture.dispose();let d=s.morphAttributes.position!==void 0,p=s.morphAttributes.normal!==void 0,m=s.morphAttributes.color!==void 0,g=s.morphAttributes.position||[],f=s.morphAttributes.normal||[],v=s.morphAttributes.color||[],_=0;d===!0&&(_=1),p===!0&&(_=2),m===!0&&(_=3);let y=s.attributes.position.count*_,S=1;y>e.maxTextureSize&&(S=Math.ceil(y/e.maxTextureSize),y=e.maxTextureSize);let w=new Float32Array(y*S*4*h),R=new ka(w,y,S,h);R.type=jn,R.needsUpdate=!0;let B=4*_;for(let D=0;D<h;D++){let J=g[D],K=f[D],V=v[D],se=y*S*4*D;for(let X=0;X<J.count;X++){let ee=X*B;d===!0&&(r.fromBufferAttribute(J,X),w[se+ee+0]=r.x,w[se+ee+1]=r.y,w[se+ee+2]=r.z,w[se+ee+3]=0),p===!0&&(r.fromBufferAttribute(K,X),w[se+ee+4]=r.x,w[se+ee+5]=r.y,w[se+ee+6]=r.z,w[se+ee+7]=0),m===!0&&(r.fromBufferAttribute(V,X),w[se+ee+8]=r.x,w[se+ee+9]=r.y,w[se+ee+10]=r.z,w[se+ee+11]=V.itemSize===4?r.w:1)}}u={count:h,texture:R,size:new pe(y,S)},n.set(s,u),s.addEventListener("dispose",G)}if(a.isInstancedMesh===!0&&a.morphTexture!==null)o.getUniforms().setValue(i,"morphTexture",a.morphTexture,t);else{let d=0;for(let m=0;m<c.length;m++)d+=c[m];let p=s.morphTargetsRelative?1:1-d;o.getUniforms().setValue(i,"morphTargetBaseInfluence",p),o.getUniforms().setValue(i,"morphTargetInfluences",c)}o.getUniforms().setValue(i,"morphTargetsTexture",u.texture,t),o.getUniforms().setValue(i,"morphTargetsTextureSize",u.size)}}}function lf(i,e,t,n){let r=new WeakMap;function a(s){let o=s.target;o.removeEventListener("dispose",a),t.remove(o.instanceMatrix),o.instanceColor!==null&&t.remove(o.instanceColor)}return{update:function(s){let o=n.render.frame,c=s.geometry,l=e.get(s,c);if(r.get(l)!==o&&(e.update(l),r.set(l,o)),s.isInstancedMesh&&(s.hasEventListener("dispose",a)===!1&&s.addEventListener("dispose",a),r.get(s)!==o&&(t.update(s.instanceMatrix,i.ARRAY_BUFFER),s.instanceColor!==null&&t.update(s.instanceColor,i.ARRAY_BUFFER),r.set(s,o))),s.isSkinnedMesh){let h=s.skeleton;r.get(h)!==o&&(h.update(),r.set(h,o))}return l},dispose:function(){r=new WeakMap}}}var Nd=new fn,vd=new Xa(1,1),Fd=new ka,Od=new $s,Bd=new Va,_d=[],yd=[],xd=new Float32Array(16),Md=new Float32Array(9),Sd=new Float32Array(4);function ma(i,e,t){let n=i[0];if(n<=0||n>0)return i;let r=e*t,a=_d[r];if(a===void 0&&(a=new Float32Array(r),_d[r]=a),e!==0){n.toArray(a,0);for(let s=1,o=0;s!==e;++s)o+=t,i[s].toArray(a,o)}return a}function zt(i,e){if(i.length!==e.length)return!1;for(let t=0,n=i.length;t<n;t++)if(i[t]!==e[t])return!1;return!0}function Ht(i,e){for(let t=0,n=e.length;t<n;t++)i[t]=e[t]}function sl(i,e){let t=yd[e];t===void 0&&(t=new Int32Array(e),yd[e]=t);for(let n=0;n!==e;++n)t[n]=i.allocateTextureUnit();return t}function cf(i,e){let t=this.cache;t[0]!==e&&(i.uniform1f(this.addr,e),t[0]=e)}function hf(i,e){let t=this.cache;if(e.x!==void 0)t[0]===e.x&&t[1]===e.y||(i.uniform2f(this.addr,e.x,e.y),t[0]=e.x,t[1]=e.y);else{if(zt(t,e))return;i.uniform2fv(this.addr,e),Ht(t,e)}}function uf(i,e){let t=this.cache;if(e.x!==void 0)t[0]===e.x&&t[1]===e.y&&t[2]===e.z||(i.uniform3f(this.addr,e.x,e.y,e.z),t[0]=e.x,t[1]=e.y,t[2]=e.z);else if(e.r!==void 0)t[0]===e.r&&t[1]===e.g&&t[2]===e.b||(i.uniform3f(this.addr,e.r,e.g,e.b),t[0]=e.r,t[1]=e.g,t[2]=e.b);else{if(zt(t,e))return;i.uniform3fv(this.addr,e),Ht(t,e)}}function df(i,e){let t=this.cache;if(e.x!==void 0)t[0]===e.x&&t[1]===e.y&&t[2]===e.z&&t[3]===e.w||(i.uniform4f(this.addr,e.x,e.y,e.z,e.w),t[0]=e.x,t[1]=e.y,t[2]=e.z,t[3]=e.w);else{if(zt(t,e))return;i.uniform4fv(this.addr,e),Ht(t,e)}}function pf(i,e){let t=this.cache,n=e.elements;if(n===void 0){if(zt(t,e))return;i.uniformMatrix2fv(this.addr,!1,e),Ht(t,e)}else{if(zt(t,n))return;Sd.set(n),i.uniformMatrix2fv(this.addr,!1,Sd),Ht(t,n)}}function ff(i,e){let t=this.cache,n=e.elements;if(n===void 0){if(zt(t,e))return;i.uniformMatrix3fv(this.addr,!1,e),Ht(t,e)}else{if(zt(t,n))return;Md.set(n),i.uniformMatrix3fv(this.addr,!1,Md),Ht(t,n)}}function mf(i,e){let t=this.cache,n=e.elements;if(n===void 0){if(zt(t,e))return;i.uniformMatrix4fv(this.addr,!1,e),Ht(t,e)}else{if(zt(t,n))return;xd.set(n),i.uniformMatrix4fv(this.addr,!1,xd),Ht(t,n)}}function gf(i,e){let t=this.cache;t[0]!==e&&(i.uniform1i(this.addr,e),t[0]=e)}function vf(i,e){let t=this.cache;if(e.x!==void 0)t[0]===e.x&&t[1]===e.y||(i.uniform2i(this.addr,e.x,e.y),t[0]=e.x,t[1]=e.y);else{if(zt(t,e))return;i.uniform2iv(this.addr,e),Ht(t,e)}}function _f(i,e){let t=this.cache;if(e.x!==void 0)t[0]===e.x&&t[1]===e.y&&t[2]===e.z||(i.uniform3i(this.addr,e.x,e.y,e.z),t[0]=e.x,t[1]=e.y,t[2]=e.z);else{if(zt(t,e))return;i.uniform3iv(this.addr,e),Ht(t,e)}}function yf(i,e){let t=this.cache;if(e.x!==void 0)t[0]===e.x&&t[1]===e.y&&t[2]===e.z&&t[3]===e.w||(i.uniform4i(this.addr,e.x,e.y,e.z,e.w),t[0]=e.x,t[1]=e.y,t[2]=e.z,t[3]=e.w);else{if(zt(t,e))return;i.uniform4iv(this.addr,e),Ht(t,e)}}function xf(i,e){let t=this.cache;t[0]!==e&&(i.uniform1ui(this.addr,e),t[0]=e)}function Mf(i,e){let t=this.cache;if(e.x!==void 0)t[0]===e.x&&t[1]===e.y||(i.uniform2ui(this.addr,e.x,e.y),t[0]=e.x,t[1]=e.y);else{if(zt(t,e))return;i.uniform2uiv(this.addr,e),Ht(t,e)}}function Sf(i,e){let t=this.cache;if(e.x!==void 0)t[0]===e.x&&t[1]===e.y&&t[2]===e.z||(i.uniform3ui(this.addr,e.x,e.y,e.z),t[0]=e.x,t[1]=e.y,t[2]=e.z);else{if(zt(t,e))return;i.uniform3uiv(this.addr,e),Ht(t,e)}}function bf(i,e){let t=this.cache;if(e.x!==void 0)t[0]===e.x&&t[1]===e.y&&t[2]===e.z&&t[3]===e.w||(i.uniform4ui(this.addr,e.x,e.y,e.z,e.w),t[0]=e.x,t[1]=e.y,t[2]=e.z,t[3]=e.w);else{if(zt(t,e))return;i.uniform4uiv(this.addr,e),Ht(t,e)}}function Tf(i,e,t){let n=this.cache,r=t.allocateTextureUnit(),a;n[0]!==r&&(i.uniform1i(this.addr,r),n[0]=r),this.type===i.SAMPLER_2D_SHADOW?(vd.compareFunction=Xc,a=vd):a=Nd,t.setTexture2D(e||a,r)}function Ef(i,e,t){let n=this.cache,r=t.allocateTextureUnit();n[0]!==r&&(i.uniform1i(this.addr,r),n[0]=r),t.setTexture3D(e||Od,r)}function wf(i,e,t){let n=this.cache,r=t.allocateTextureUnit();n[0]!==r&&(i.uniform1i(this.addr,r),n[0]=r),t.setTextureCube(e||Bd,r)}function Af(i,e,t){let n=this.cache,r=t.allocateTextureUnit();n[0]!==r&&(i.uniform1i(this.addr,r),n[0]=r),t.setTexture2DArray(e||Fd,r)}function Rf(i,e){i.uniform1fv(this.addr,e)}function Cf(i,e){let t=ma(e,this.size,2);i.uniform2fv(this.addr,t)}function Pf(i,e){let t=ma(e,this.size,3);i.uniform3fv(this.addr,t)}function If(i,e){let t=ma(e,this.size,4);i.uniform4fv(this.addr,t)}function Lf(i,e){let t=ma(e,this.size,4);i.uniformMatrix2fv(this.addr,!1,t)}function Df(i,e){let t=ma(e,this.size,9);i.uniformMatrix3fv(this.addr,!1,t)}function Uf(i,e){let t=ma(e,this.size,16);i.uniformMatrix4fv(this.addr,!1,t)}function Nf(i,e){i.uniform1iv(this.addr,e)}function Ff(i,e){i.uniform2iv(this.addr,e)}function Of(i,e){i.uniform3iv(this.addr,e)}function Bf(i,e){i.uniform4iv(this.addr,e)}function kf(i,e){i.uniform1uiv(this.addr,e)}function zf(i,e){i.uniform2uiv(this.addr,e)}function Hf(i,e){i.uniform3uiv(this.addr,e)}function Gf(i,e){i.uniform4uiv(this.addr,e)}function Vf(i,e,t){let n=this.cache,r=e.length,a=sl(t,r);zt(n,a)||(i.uniform1iv(this.addr,a),Ht(n,a));for(let s=0;s!==r;++s)t.setTexture2D(e[s]||Nd,a[s])}function Wf(i,e,t){let n=this.cache,r=e.length,a=sl(t,r);zt(n,a)||(i.uniform1iv(this.addr,a),Ht(n,a));for(let s=0;s!==r;++s)t.setTexture3D(e[s]||Od,a[s])}function Xf(i,e,t){let n=this.cache,r=e.length,a=sl(t,r);zt(n,a)||(i.uniform1iv(this.addr,a),Ht(n,a));for(let s=0;s!==r;++s)t.setTextureCube(e[s]||Bd,a[s])}function jf(i,e,t){let n=this.cache,r=e.length,a=sl(t,r);zt(n,a)||(i.uniform1iv(this.addr,a),Ht(n,a));for(let s=0;s!==r;++s)t.setTexture2DArray(e[s]||Fd,a[s])}var ah=class{constructor(e,t,n){this.id=e,this.addr=n,this.cache=[],this.type=t.type,this.setValue=(function(r){switch(r){case 5126:return cf;case 35664:return hf;case 35665:return uf;case 35666:return df;case 35674:return pf;case 35675:return ff;case 35676:return mf;case 5124:case 35670:return gf;case 35667:case 35671:return vf;case 35668:case 35672:return _f;case 35669:case 35673:return yf;case 5125:return xf;case 36294:return Mf;case 36295:return Sf;case 36296:return bf;case 35678:case 36198:case 36298:case 36306:case 35682:return Tf;case 35679:case 36299:case 36307:return Ef;case 35680:case 36300:case 36308:case 36293:return wf;case 36289:case 36303:case 36311:case 36292:return Af}})(t.type)}},sh=class{constructor(e,t,n){this.id=e,this.addr=n,this.cache=[],this.type=t.type,this.size=t.size,this.setValue=(function(r){switch(r){case 5126:return Rf;case 35664:return Cf;case 35665:return Pf;case 35666:return If;case 35674:return Lf;case 35675:return Df;case 35676:return Uf;case 5124:case 35670:return Nf;case 35667:case 35671:return Ff;case 35668:case 35672:return Of;case 35669:case 35673:return Bf;case 5125:return kf;case 36294:return zf;case 36295:return Hf;case 36296:return Gf;case 35678:case 36198:case 36298:case 36306:case 35682:return Vf;case 35679:case 36299:case 36307:return Wf;case 35680:case 36300:case 36308:case 36293:return Xf;case 36289:case 36303:case 36311:case 36292:return jf}})(t.type)}},oh=class{constructor(e){this.id=e,this.seq=[],this.map={}}setValue(e,t,n){let r=this.seq;for(let a=0,s=r.length;a!==s;++a){let o=r[a];o.setValue(e,t[o.id],n)}}},rh=/(\w+)(\])?(\[|\.)?/g;function bd(i,e){i.seq.push(e),i.map[e.id]=e}function qf(i,e,t){let n=i.name,r=n.length;for(rh.lastIndex=0;;){let a=rh.exec(n),s=rh.lastIndex,o=a[1],c=a[2]==="]",l=a[3];if(c&&(o|=0),l===void 0||l==="["&&s+2===r){bd(t,l===void 0?new ah(o,i,e):new sh(o,i,e));break}{let h=t.map[o];h===void 0&&(h=new oh(o),bd(t,h)),t=h}}}var pa=class{constructor(e,t){this.seq=[],this.map={};let n=e.getProgramParameter(t,e.ACTIVE_UNIFORMS);for(let r=0;r<n;++r){let a=e.getActiveUniform(t,r);qf(a,e.getUniformLocation(t,a.name),this)}}setValue(e,t,n,r){let a=this.map[t];a!==void 0&&a.setValue(e,n,r)}setOptional(e,t,n){let r=t[n];r!==void 0&&this.setValue(e,n,r)}static upload(e,t,n,r){for(let a=0,s=t.length;a!==s;++a){let o=t[a],c=n[o.id];c.needsUpdate!==!1&&o.setValue(e,c.value,r)}}static seqWithValue(e,t){let n=[];for(let r=0,a=e.length;r!==a;++r){let s=e[r];s.id in t&&n.push(s)}return n}};function Td(i,e,t){let n=i.createShader(e);return i.shaderSource(n,t),i.compileShader(n),n}var Yf=0,Ed=new Qe;function wd(i,e,t){let n=i.getShaderParameter(e,i.COMPILE_STATUS),r=(i.getShaderInfoLog(e)||"").trim();if(n&&r==="")return"";let a=/ERROR: 0:(\d+)/.exec(r);if(a){let s=parseInt(a[1]);return t.toUpperCase()+`

`+r+`

`+(function(o,c){let l=o.split(`
`),h=[],u=Math.max(c-6,0),d=Math.min(c+6,l.length);for(let p=u;p<d;p++){let m=p+1;h.push(`${m===c?">":" "} ${m}: ${l[p]}`)}return h.join(`
`)})(i.getShaderSource(e),s)}return r}function Zf(i,e){let t=(function(n){ht._getMatrix(Ed,ht.workingColorSpace,n);let r=`mat3( ${Ed.elements.map(a=>a.toFixed(4))} )`;switch(ht.getTransfer(n)){case Fa:return[r,"LinearTransferOETF"];case dt:return[r,"sRGBTransferOETF"];default:return console.warn("THREE.WebGLProgram: Unsupported color space: ",n),[r,"LinearTransferOETF"]}})(e);return[`vec4 ${i}( vec4 value ) {`,`	return ${t[1]}( vec4( value.rgb * ${t[0]}, value.a ) );`,"}"].join(`
`)}function Jf(i,e){let t;switch(e){case Ou:t="Linear";break;case Bu:t="Reinhard";break;case ku:t="Cineon";break;case Vo:t="ACESFilmic";break;case Hu:t="AgX";break;case Gu:t="Neutral";break;case zu:t="Custom";break;default:console.warn("THREE.WebGLProgram: Unsupported toneMapping:",e),t="Linear"}return"vec3 "+i+"( vec3 color ) { return "+t+"ToneMapping( color ); }"}var rl=new E;function Kf(){return ht.getLuminanceCoefficients(rl),["float luminance( const in vec3 rgb ) {",`	const vec3 weights = vec3( ${rl.x.toFixed(4)}, ${rl.y.toFixed(4)}, ${rl.z.toFixed(4)} );`,"	return dot( weights, rgb );","}"].join(`
`)}function ds(i){return i!==""}function Ad(i,e){let t=e.numSpotLightShadows+e.numSpotLightMaps-e.numSpotLightShadowsWithMaps;return i.replace(/NUM_DIR_LIGHTS/g,e.numDirLights).replace(/NUM_SPOT_LIGHTS/g,e.numSpotLights).replace(/NUM_SPOT_LIGHT_MAPS/g,e.numSpotLightMaps).replace(/NUM_SPOT_LIGHT_COORDS/g,t).replace(/NUM_RECT_AREA_LIGHTS/g,e.numRectAreaLights).replace(/NUM_POINT_LIGHTS/g,e.numPointLights).replace(/NUM_HEMI_LIGHTS/g,e.numHemiLights).replace(/NUM_DIR_LIGHT_SHADOWS/g,e.numDirLightShadows).replace(/NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS/g,e.numSpotLightShadowsWithMaps).replace(/NUM_SPOT_LIGHT_SHADOWS/g,e.numSpotLightShadows).replace(/NUM_POINT_LIGHT_SHADOWS/g,e.numPointLightShadows)}function Rd(i,e){return i.replace(/NUM_CLIPPING_PLANES/g,e.numClippingPlanes).replace(/UNION_CLIPPING_PLANES/g,e.numClippingPlanes-e.numClipIntersection)}var $f=/^[ \t]*#include +<([\w\d./]+)>/gm;function lh(i){return i.replace($f,em)}var Qf=new Map;function em(i,e){let t=rt[e];if(t===void 0){let n=Qf.get(e);if(n===void 0)throw new Error("Can not resolve #include <"+e+">");t=rt[n],console.warn('THREE.WebGLRenderer: Shader chunk "%s" has been deprecated. Use "%s" instead.',e,n)}return lh(t)}var tm=/#pragma unroll_loop_start\s+for\s*\(\s*int\s+i\s*=\s*(\d+)\s*;\s*i\s*<\s*(\d+)\s*;\s*i\s*\+\+\s*\)\s*{([\s\S]+?)}\s+#pragma unroll_loop_end/g;function Cd(i){return i.replace(tm,nm)}function nm(i,e,t,n){let r="";for(let a=parseInt(e);a<parseInt(t);a++)r+=n.replace(/\[\s*i\s*\]/g,"[ "+a+" ]").replace(/UNROLLED_LOOP_INDEX/g,a);return r}function Pd(i){let e=`precision ${i.precision} float;
	precision ${i.precision} int;
	precision ${i.precision} sampler2D;
	precision ${i.precision} samplerCube;
	precision ${i.precision} sampler3D;
	precision ${i.precision} sampler2DArray;
	precision ${i.precision} sampler2DShadow;
	precision ${i.precision} samplerCubeShadow;
	precision ${i.precision} sampler2DArrayShadow;
	precision ${i.precision} isampler2D;
	precision ${i.precision} isampler3D;
	precision ${i.precision} isamplerCube;
	precision ${i.precision} isampler2DArray;
	precision ${i.precision} usampler2D;
	precision ${i.precision} usampler3D;
	precision ${i.precision} usamplerCube;
	precision ${i.precision} usampler2DArray;
	`;return i.precision==="highp"?e+=`
#define HIGH_PRECISION`:i.precision==="mediump"?e+=`
#define MEDIUM_PRECISION`:i.precision==="lowp"&&(e+=`
#define LOW_PRECISION`),e}function im(i,e,t,n){let r=i.getContext(),a=t.defines,s=t.vertexShader,o=t.fragmentShader,c=(function(K){let V="SHADOWMAP_TYPE_BASIC";return K.shadowMapType===oc?V="SHADOWMAP_TYPE_PCF":K.shadowMapType===pu?V="SHADOWMAP_TYPE_PCF_SOFT":K.shadowMapType===si&&(V="SHADOWMAP_TYPE_VSM"),V})(t),l=(function(K){let V="ENVMAP_TYPE_CUBE";if(K.envMap)switch(K.envMapMode){case la:case yr:V="ENVMAP_TYPE_CUBE";break;case os:V="ENVMAP_TYPE_CUBE_UV"}return V})(t),h=(function(K){let V="ENVMAP_MODE_REFLECTION";return K.envMap&&K.envMapMode===yr&&(V="ENVMAP_MODE_REFRACTION"),V})(t),u=(function(K){let V="ENVMAP_BLENDING_NONE";if(K.envMap)switch(K.combine){case Uu:V="ENVMAP_BLENDING_MULTIPLY";break;case Nu:V="ENVMAP_BLENDING_MIX";break;case Fu:V="ENVMAP_BLENDING_ADD"}return V})(t),d=(function(K){let V=K.envMapCubeUVHeight;if(V===null)return null;let se=Math.log2(V)-2,X=1/V;return{texelWidth:1/(3*Math.max(Math.pow(2,se),112)),texelHeight:X,maxMip:se}})(t),p=(function(K){return[K.extensionClipCullDistance?"#extension GL_ANGLE_clip_cull_distance : require":"",K.extensionMultiDraw?"#extension GL_ANGLE_multi_draw : require":""].filter(ds).join(`
`)})(t),m=(function(K){let V=[];for(let se in K){let X=K[se];X!==!1&&V.push("#define "+se+" "+X)}return V.join(`
`)})(a),g=r.createProgram(),f,v,_=t.glslVersion?"#version "+t.glslVersion+`
`:"";t.isRawShaderMaterial?(f=["#define SHADER_TYPE "+t.shaderType,"#define SHADER_NAME "+t.shaderName,m].filter(ds).join(`
`),f.length>0&&(f+=`
`),v=["#define SHADER_TYPE "+t.shaderType,"#define SHADER_NAME "+t.shaderName,m].filter(ds).join(`
`),v.length>0&&(v+=`
`)):(f=[Pd(t),"#define SHADER_TYPE "+t.shaderType,"#define SHADER_NAME "+t.shaderName,m,t.extensionClipCullDistance?"#define USE_CLIP_DISTANCE":"",t.batching?"#define USE_BATCHING":"",t.batchingColor?"#define USE_BATCHING_COLOR":"",t.instancing?"#define USE_INSTANCING":"",t.instancingColor?"#define USE_INSTANCING_COLOR":"",t.instancingMorph?"#define USE_INSTANCING_MORPH":"",t.useFog&&t.fog?"#define USE_FOG":"",t.useFog&&t.fogExp2?"#define FOG_EXP2":"",t.map?"#define USE_MAP":"",t.envMap?"#define USE_ENVMAP":"",t.envMap?"#define "+h:"",t.lightMap?"#define USE_LIGHTMAP":"",t.aoMap?"#define USE_AOMAP":"",t.bumpMap?"#define USE_BUMPMAP":"",t.normalMap?"#define USE_NORMALMAP":"",t.normalMapObjectSpace?"#define USE_NORMALMAP_OBJECTSPACE":"",t.normalMapTangentSpace?"#define USE_NORMALMAP_TANGENTSPACE":"",t.displacementMap?"#define USE_DISPLACEMENTMAP":"",t.emissiveMap?"#define USE_EMISSIVEMAP":"",t.anisotropy?"#define USE_ANISOTROPY":"",t.anisotropyMap?"#define USE_ANISOTROPYMAP":"",t.clearcoatMap?"#define USE_CLEARCOATMAP":"",t.clearcoatRoughnessMap?"#define USE_CLEARCOAT_ROUGHNESSMAP":"",t.clearcoatNormalMap?"#define USE_CLEARCOAT_NORMALMAP":"",t.iridescenceMap?"#define USE_IRIDESCENCEMAP":"",t.iridescenceThicknessMap?"#define USE_IRIDESCENCE_THICKNESSMAP":"",t.specularMap?"#define USE_SPECULARMAP":"",t.specularColorMap?"#define USE_SPECULAR_COLORMAP":"",t.specularIntensityMap?"#define USE_SPECULAR_INTENSITYMAP":"",t.roughnessMap?"#define USE_ROUGHNESSMAP":"",t.metalnessMap?"#define USE_METALNESSMAP":"",t.alphaMap?"#define USE_ALPHAMAP":"",t.alphaHash?"#define USE_ALPHAHASH":"",t.transmission?"#define USE_TRANSMISSION":"",t.transmissionMap?"#define USE_TRANSMISSIONMAP":"",t.thicknessMap?"#define USE_THICKNESSMAP":"",t.sheenColorMap?"#define USE_SHEEN_COLORMAP":"",t.sheenRoughnessMap?"#define USE_SHEEN_ROUGHNESSMAP":"",t.mapUv?"#define MAP_UV "+t.mapUv:"",t.alphaMapUv?"#define ALPHAMAP_UV "+t.alphaMapUv:"",t.lightMapUv?"#define LIGHTMAP_UV "+t.lightMapUv:"",t.aoMapUv?"#define AOMAP_UV "+t.aoMapUv:"",t.emissiveMapUv?"#define EMISSIVEMAP_UV "+t.emissiveMapUv:"",t.bumpMapUv?"#define BUMPMAP_UV "+t.bumpMapUv:"",t.normalMapUv?"#define NORMALMAP_UV "+t.normalMapUv:"",t.displacementMapUv?"#define DISPLACEMENTMAP_UV "+t.displacementMapUv:"",t.metalnessMapUv?"#define METALNESSMAP_UV "+t.metalnessMapUv:"",t.roughnessMapUv?"#define ROUGHNESSMAP_UV "+t.roughnessMapUv:"",t.anisotropyMapUv?"#define ANISOTROPYMAP_UV "+t.anisotropyMapUv:"",t.clearcoatMapUv?"#define CLEARCOATMAP_UV "+t.clearcoatMapUv:"",t.clearcoatNormalMapUv?"#define CLEARCOAT_NORMALMAP_UV "+t.clearcoatNormalMapUv:"",t.clearcoatRoughnessMapUv?"#define CLEARCOAT_ROUGHNESSMAP_UV "+t.clearcoatRoughnessMapUv:"",t.iridescenceMapUv?"#define IRIDESCENCEMAP_UV "+t.iridescenceMapUv:"",t.iridescenceThicknessMapUv?"#define IRIDESCENCE_THICKNESSMAP_UV "+t.iridescenceThicknessMapUv:"",t.sheenColorMapUv?"#define SHEEN_COLORMAP_UV "+t.sheenColorMapUv:"",t.sheenRoughnessMapUv?"#define SHEEN_ROUGHNESSMAP_UV "+t.sheenRoughnessMapUv:"",t.specularMapUv?"#define SPECULARMAP_UV "+t.specularMapUv:"",t.specularColorMapUv?"#define SPECULAR_COLORMAP_UV "+t.specularColorMapUv:"",t.specularIntensityMapUv?"#define SPECULAR_INTENSITYMAP_UV "+t.specularIntensityMapUv:"",t.transmissionMapUv?"#define TRANSMISSIONMAP_UV "+t.transmissionMapUv:"",t.thicknessMapUv?"#define THICKNESSMAP_UV "+t.thicknessMapUv:"",t.vertexTangents&&t.flatShading===!1?"#define USE_TANGENT":"",t.vertexColors?"#define USE_COLOR":"",t.vertexAlphas?"#define USE_COLOR_ALPHA":"",t.vertexUv1s?"#define USE_UV1":"",t.vertexUv2s?"#define USE_UV2":"",t.vertexUv3s?"#define USE_UV3":"",t.pointsUvs?"#define USE_POINTS_UV":"",t.flatShading?"#define FLAT_SHADED":"",t.skinning?"#define USE_SKINNING":"",t.morphTargets?"#define USE_MORPHTARGETS":"",t.morphNormals&&t.flatShading===!1?"#define USE_MORPHNORMALS":"",t.morphColors?"#define USE_MORPHCOLORS":"",t.morphTargetsCount>0?"#define MORPHTARGETS_TEXTURE_STRIDE "+t.morphTextureStride:"",t.morphTargetsCount>0?"#define MORPHTARGETS_COUNT "+t.morphTargetsCount:"",t.doubleSided?"#define DOUBLE_SIDED":"",t.flipSided?"#define FLIP_SIDED":"",t.shadowMapEnabled?"#define USE_SHADOWMAP":"",t.shadowMapEnabled?"#define "+c:"",t.sizeAttenuation?"#define USE_SIZEATTENUATION":"",t.numLightProbes>0?"#define USE_LIGHT_PROBES":"",t.logarithmicDepthBuffer?"#define USE_LOGARITHMIC_DEPTH_BUFFER":"",t.reversedDepthBuffer?"#define USE_REVERSED_DEPTH_BUFFER":"","uniform mat4 modelMatrix;","uniform mat4 modelViewMatrix;","uniform mat4 projectionMatrix;","uniform mat4 viewMatrix;","uniform mat3 normalMatrix;","uniform vec3 cameraPosition;","uniform bool isOrthographic;","#ifdef USE_INSTANCING","	attribute mat4 instanceMatrix;","#endif","#ifdef USE_INSTANCING_COLOR","	attribute vec3 instanceColor;","#endif","#ifdef USE_INSTANCING_MORPH","	uniform sampler2D morphTexture;","#endif","attribute vec3 position;","attribute vec3 normal;","attribute vec2 uv;","#ifdef USE_UV1","	attribute vec2 uv1;","#endif","#ifdef USE_UV2","	attribute vec2 uv2;","#endif","#ifdef USE_UV3","	attribute vec2 uv3;","#endif","#ifdef USE_TANGENT","	attribute vec4 tangent;","#endif","#if defined( USE_COLOR_ALPHA )","	attribute vec4 color;","#elif defined( USE_COLOR )","	attribute vec3 color;","#endif","#ifdef USE_SKINNING","	attribute vec4 skinIndex;","	attribute vec4 skinWeight;","#endif",`
`].filter(ds).join(`
`),v=[Pd(t),"#define SHADER_TYPE "+t.shaderType,"#define SHADER_NAME "+t.shaderName,m,t.useFog&&t.fog?"#define USE_FOG":"",t.useFog&&t.fogExp2?"#define FOG_EXP2":"",t.alphaToCoverage?"#define ALPHA_TO_COVERAGE":"",t.map?"#define USE_MAP":"",t.matcap?"#define USE_MATCAP":"",t.envMap?"#define USE_ENVMAP":"",t.envMap?"#define "+l:"",t.envMap?"#define "+h:"",t.envMap?"#define "+u:"",d?"#define CUBEUV_TEXEL_WIDTH "+d.texelWidth:"",d?"#define CUBEUV_TEXEL_HEIGHT "+d.texelHeight:"",d?"#define CUBEUV_MAX_MIP "+d.maxMip+".0":"",t.lightMap?"#define USE_LIGHTMAP":"",t.aoMap?"#define USE_AOMAP":"",t.bumpMap?"#define USE_BUMPMAP":"",t.normalMap?"#define USE_NORMALMAP":"",t.normalMapObjectSpace?"#define USE_NORMALMAP_OBJECTSPACE":"",t.normalMapTangentSpace?"#define USE_NORMALMAP_TANGENTSPACE":"",t.emissiveMap?"#define USE_EMISSIVEMAP":"",t.anisotropy?"#define USE_ANISOTROPY":"",t.anisotropyMap?"#define USE_ANISOTROPYMAP":"",t.clearcoat?"#define USE_CLEARCOAT":"",t.clearcoatMap?"#define USE_CLEARCOATMAP":"",t.clearcoatRoughnessMap?"#define USE_CLEARCOAT_ROUGHNESSMAP":"",t.clearcoatNormalMap?"#define USE_CLEARCOAT_NORMALMAP":"",t.dispersion?"#define USE_DISPERSION":"",t.iridescence?"#define USE_IRIDESCENCE":"",t.iridescenceMap?"#define USE_IRIDESCENCEMAP":"",t.iridescenceThicknessMap?"#define USE_IRIDESCENCE_THICKNESSMAP":"",t.specularMap?"#define USE_SPECULARMAP":"",t.specularColorMap?"#define USE_SPECULAR_COLORMAP":"",t.specularIntensityMap?"#define USE_SPECULAR_INTENSITYMAP":"",t.roughnessMap?"#define USE_ROUGHNESSMAP":"",t.metalnessMap?"#define USE_METALNESSMAP":"",t.alphaMap?"#define USE_ALPHAMAP":"",t.alphaTest?"#define USE_ALPHATEST":"",t.alphaHash?"#define USE_ALPHAHASH":"",t.sheen?"#define USE_SHEEN":"",t.sheenColorMap?"#define USE_SHEEN_COLORMAP":"",t.sheenRoughnessMap?"#define USE_SHEEN_ROUGHNESSMAP":"",t.transmission?"#define USE_TRANSMISSION":"",t.transmissionMap?"#define USE_TRANSMISSIONMAP":"",t.thicknessMap?"#define USE_THICKNESSMAP":"",t.vertexTangents&&t.flatShading===!1?"#define USE_TANGENT":"",t.vertexColors||t.instancingColor||t.batchingColor?"#define USE_COLOR":"",t.vertexAlphas?"#define USE_COLOR_ALPHA":"",t.vertexUv1s?"#define USE_UV1":"",t.vertexUv2s?"#define USE_UV2":"",t.vertexUv3s?"#define USE_UV3":"",t.pointsUvs?"#define USE_POINTS_UV":"",t.gradientMap?"#define USE_GRADIENTMAP":"",t.flatShading?"#define FLAT_SHADED":"",t.doubleSided?"#define DOUBLE_SIDED":"",t.flipSided?"#define FLIP_SIDED":"",t.shadowMapEnabled?"#define USE_SHADOWMAP":"",t.shadowMapEnabled?"#define "+c:"",t.premultipliedAlpha?"#define PREMULTIPLIED_ALPHA":"",t.numLightProbes>0?"#define USE_LIGHT_PROBES":"",t.decodeVideoTexture?"#define DECODE_VIDEO_TEXTURE":"",t.decodeVideoTextureEmissive?"#define DECODE_VIDEO_TEXTURE_EMISSIVE":"",t.logarithmicDepthBuffer?"#define USE_LOGARITHMIC_DEPTH_BUFFER":"",t.reversedDepthBuffer?"#define USE_REVERSED_DEPTH_BUFFER":"","uniform mat4 viewMatrix;","uniform vec3 cameraPosition;","uniform bool isOrthographic;",t.toneMapping!==Pi?"#define TONE_MAPPING":"",t.toneMapping!==Pi?rt.tonemapping_pars_fragment:"",t.toneMapping!==Pi?Jf("toneMapping",t.toneMapping):"",t.dithering?"#define DITHERING":"",t.opaque?"#define OPAQUE":"",rt.colorspace_pars_fragment,Zf("linearToOutputTexel",t.outputColorSpace),Kf(),t.useDepthPacking?"#define DEPTH_PACKING "+t.depthPacking:"",`
`].filter(ds).join(`
`)),s=lh(s),s=Ad(s,t),s=Rd(s,t),o=lh(o),o=Ad(o,t),o=Rd(o,t),s=Cd(s),o=Cd(o),t.isRawShaderMaterial!==!0&&(_=`#version 300 es
`,f=[p,"#define attribute in","#define varying out","#define texture2D texture"].join(`
`)+`
`+f,v=["#define varying in",t.glslVersion===qc?"":"layout(location = 0) out highp vec4 pc_fragColor;",t.glslVersion===qc?"":"#define gl_FragColor pc_fragColor","#define gl_FragDepthEXT gl_FragDepth","#define texture2D texture","#define textureCube texture","#define texture2DProj textureProj","#define texture2DLodEXT textureLod","#define texture2DProjLodEXT textureProjLod","#define textureCubeLodEXT textureLod","#define texture2DGradEXT textureGrad","#define texture2DProjGradEXT textureProjGrad","#define textureCubeGradEXT textureGrad"].join(`
`)+`
`+v);let y=_+f+s,S=_+v+o,w=Td(r,r.VERTEX_SHADER,y),R=Td(r,r.FRAGMENT_SHADER,S);function B(K){if(i.debug.checkShaderErrors){let V=r.getProgramInfoLog(g)||"",se=r.getShaderInfoLog(w)||"",X=r.getShaderInfoLog(R)||"",ee=V.trim(),Q=se.trim(),me=X.trim(),ae=!0,be=!0;if(r.getProgramParameter(g,r.LINK_STATUS)===!1)if(ae=!1,typeof i.debug.onShaderError=="function")i.debug.onShaderError(r,g,w,R);else{let Be=wd(r,w,"vertex"),Ie=wd(r,R,"fragment");console.error("THREE.WebGLProgram: Shader Error "+r.getError()+" - VALIDATE_STATUS "+r.getProgramParameter(g,r.VALIDATE_STATUS)+`

Material Name: `+K.name+`
Material Type: `+K.type+`

Program Info Log: `+ee+`
`+Be+`
`+Ie)}else ee!==""?console.warn("THREE.WebGLProgram: Program Info Log:",ee):Q!==""&&me!==""||(be=!1);be&&(K.diagnostics={runnable:ae,programLog:ee,vertexShader:{log:Q,prefix:f},fragmentShader:{log:me,prefix:v}})}r.deleteShader(w),r.deleteShader(R),G=new pa(r,g),D=(function(V,se){let X={},ee=V.getProgramParameter(se,V.ACTIVE_ATTRIBUTES);for(let Q=0;Q<ee;Q++){let me=V.getActiveAttrib(se,Q),ae=me.name,be=1;me.type===V.FLOAT_MAT2&&(be=2),me.type===V.FLOAT_MAT3&&(be=3),me.type===V.FLOAT_MAT4&&(be=4),X[ae]={type:me.type,location:V.getAttribLocation(se,ae),locationSize:be}}return X})(r,g)}let G,D;r.attachShader(g,w),r.attachShader(g,R),t.index0AttributeName!==void 0?r.bindAttribLocation(g,0,t.index0AttributeName):t.morphTargets===!0&&r.bindAttribLocation(g,0,"position"),r.linkProgram(g),this.getUniforms=function(){return G===void 0&&B(this),G},this.getAttributes=function(){return D===void 0&&B(this),D};let J=t.rendererExtensionParallelShaderCompile===!1;return this.isReady=function(){return J===!1&&(J=r.getProgramParameter(g,37297)),J},this.destroy=function(){n.releaseStatesOfProgram(this),r.deleteProgram(g),this.program=void 0},this.type=t.shaderType,this.name=t.shaderName,this.id=Yf++,this.cacheKey=e,this.usedTimes=1,this.program=g,this.vertexShader=w,this.fragmentShader=R,this}var rm=0,ch=class{constructor(){this.shaderCache=new Map,this.materialCache=new Map}update(e){let t=e.vertexShader,n=e.fragmentShader,r=this._getShaderStage(t),a=this._getShaderStage(n),s=this._getShaderCacheForMaterial(e);return s.has(r)===!1&&(s.add(r),r.usedTimes++),s.has(a)===!1&&(s.add(a),a.usedTimes++),this}remove(e){let t=this.materialCache.get(e);for(let n of t)n.usedTimes--,n.usedTimes===0&&this.shaderCache.delete(n.code);return this.materialCache.delete(e),this}getVertexShaderID(e){return this._getShaderStage(e.vertexShader).id}getFragmentShaderID(e){return this._getShaderStage(e.fragmentShader).id}dispose(){this.shaderCache.clear(),this.materialCache.clear()}_getShaderCacheForMaterial(e){let t=this.materialCache,n=t.get(e);return n===void 0&&(n=new Set,t.set(e,n)),n}_getShaderStage(e){let t=this.shaderCache,n=t.get(e);return n===void 0&&(n=new hh(e),t.set(e,n)),n}},hh=class{constructor(e){this.id=rm++,this.code=e,this.usedTimes=0}};function am(i,e,t,n,r,a,s){let o=new za,c=new ch,l=new Set,h=[],u=r.logarithmicDepthBuffer,d=r.vertexTextures,p=r.precision,m={MeshDepthMaterial:"depth",MeshDistanceMaterial:"distanceRGBA",MeshNormalMaterial:"normal",MeshBasicMaterial:"basic",MeshLambertMaterial:"lambert",MeshPhongMaterial:"phong",MeshToonMaterial:"toon",MeshStandardMaterial:"physical",MeshPhysicalMaterial:"physical",MeshMatcapMaterial:"matcap",LineBasicMaterial:"basic",LineDashedMaterial:"dashed",PointsMaterial:"points",ShadowMaterial:"shadow",SpriteMaterial:"sprite"};function g(f){return l.add(f),f===0?"uv":`uv${f}`}return{getParameters:function(f,v,_,y,S){let w=y.fog,R=S.geometry,B=f.isMeshStandardMaterial?y.environment:null,G=(f.isMeshStandardMaterial?t:e).get(f.envMap||B),D=G&&G.mapping===os?G.image.height:null,J=m[f.type];f.precision!==null&&(p=r.getMaxPrecision(f.precision),p!==f.precision&&console.warn("THREE.WebGLProgram.getParameters:",f.precision,"not supported, using",p,"instead."));let K=R.morphAttributes.position||R.morphAttributes.normal||R.morphAttributes.color,V=K!==void 0?K.length:0,se,X,ee,Q,me=0;if(R.morphAttributes.position!==void 0&&(me=1),R.morphAttributes.normal!==void 0&&(me=2),R.morphAttributes.color!==void 0&&(me=3),J){let Ct=hi[J];se=Ct.vertexShader,X=Ct.fragmentShader}else se=f.vertexShader,X=f.fragmentShader,c.update(f),ee=c.getVertexShaderID(f),Q=c.getFragmentShaderID(f);let ae=i.getRenderTarget(),be=i.state.buffers.depth.getReversed(),Be=S.isInstancedMesh===!0,Ie=S.isBatchedMesh===!0,Ne=!!f.map,le=!!f.matcap,re=!!G,ne=!!f.aoMap,Oe=!!f.lightMap,Ge=!!f.bumpMap,T=!!f.normalMap,b=!!f.displacementMap,H=!!f.emissiveMap,U=!!f.metalnessMap,M=!!f.roughnessMap,A=f.anisotropy>0,F=f.clearcoat>0,P=f.dispersion>0,te=f.iridescence>0,j=f.sheen>0,q=f.transmission>0,he=A&&!!f.anisotropyMap,Se=F&&!!f.clearcoatMap,ue=F&&!!f.clearcoatNormalMap,Re=F&&!!f.clearcoatRoughnessMap,De=te&&!!f.iridescenceMap,Te=te&&!!f.iridescenceThicknessMap,Ue=j&&!!f.sheenColorMap,We=j&&!!f.sheenRoughnessMap,it=!!f.specularMap,Ee=!!f.specularColorMap,ke=!!f.specularIntensityMap,Xe=q&&!!f.transmissionMap,Tt=q&&!!f.thicknessMap,Ce=!!f.gradientMap,ot=!!f.alphaMap,Ke=f.alphaTest>0,Ut=!!f.alphaHash,Et=!!f.extensions,N=Pi;f.toneMapped&&(ae!==null&&ae.isXRRenderTarget!==!0||(N=i.toneMapping));let ut={shaderID:J,shaderType:f.type,shaderName:f.name,vertexShader:se,fragmentShader:X,defines:f.defines,customVertexShaderID:ee,customFragmentShaderID:Q,isRawShaderMaterial:f.isRawShaderMaterial===!0,glslVersion:f.glslVersion,precision:p,batching:Ie,batchingColor:Ie&&S._colorsTexture!==null,instancing:Be,instancingColor:Be&&S.instanceColor!==null,instancingMorph:Be&&S.morphTexture!==null,supportsVertexTextures:d,outputColorSpace:ae===null?i.outputColorSpace:ae.isXRRenderTarget===!0?ae.texture.colorSpace:pr,alphaToCoverage:!!f.alphaToCoverage,map:Ne,matcap:le,envMap:re,envMapMode:re&&G.mapping,envMapCubeUVHeight:D,aoMap:ne,lightMap:Oe,bumpMap:Ge,normalMap:T,displacementMap:d&&b,emissiveMap:H,normalMapObjectSpace:T&&f.normalMapType===Zu,normalMapTangentSpace:T&&f.normalMapType===Yu,metalnessMap:U,roughnessMap:M,anisotropy:A,anisotropyMap:he,clearcoat:F,clearcoatMap:Se,clearcoatNormalMap:ue,clearcoatRoughnessMap:Re,dispersion:P,iridescence:te,iridescenceMap:De,iridescenceThicknessMap:Te,sheen:j,sheenColorMap:Ue,sheenRoughnessMap:We,specularMap:it,specularColorMap:Ee,specularIntensityMap:ke,transmission:q,transmissionMap:Xe,thicknessMap:Tt,gradientMap:Ce,opaque:f.transparent===!1&&f.blending===_r&&f.alphaToCoverage===!1,alphaMap:ot,alphaTest:Ke,alphaHash:Ut,combine:f.combine,mapUv:Ne&&g(f.map.channel),aoMapUv:ne&&g(f.aoMap.channel),lightMapUv:Oe&&g(f.lightMap.channel),bumpMapUv:Ge&&g(f.bumpMap.channel),normalMapUv:T&&g(f.normalMap.channel),displacementMapUv:b&&g(f.displacementMap.channel),emissiveMapUv:H&&g(f.emissiveMap.channel),metalnessMapUv:U&&g(f.metalnessMap.channel),roughnessMapUv:M&&g(f.roughnessMap.channel),anisotropyMapUv:he&&g(f.anisotropyMap.channel),clearcoatMapUv:Se&&g(f.clearcoatMap.channel),clearcoatNormalMapUv:ue&&g(f.clearcoatNormalMap.channel),clearcoatRoughnessMapUv:Re&&g(f.clearcoatRoughnessMap.channel),iridescenceMapUv:De&&g(f.iridescenceMap.channel),iridescenceThicknessMapUv:Te&&g(f.iridescenceThicknessMap.channel),sheenColorMapUv:Ue&&g(f.sheenColorMap.channel),sheenRoughnessMapUv:We&&g(f.sheenRoughnessMap.channel),specularMapUv:it&&g(f.specularMap.channel),specularColorMapUv:Ee&&g(f.specularColorMap.channel),specularIntensityMapUv:ke&&g(f.specularIntensityMap.channel),transmissionMapUv:Xe&&g(f.transmissionMap.channel),thicknessMapUv:Tt&&g(f.thicknessMap.channel),alphaMapUv:ot&&g(f.alphaMap.channel),vertexTangents:!!R.attributes.tangent&&(T||A),vertexColors:f.vertexColors,vertexAlphas:f.vertexColors===!0&&!!R.attributes.color&&R.attributes.color.itemSize===4,pointsUvs:S.isPoints===!0&&!!R.attributes.uv&&(Ne||ot),fog:!!w,useFog:f.fog===!0,fogExp2:!!w&&w.isFogExp2,flatShading:f.flatShading===!0&&f.wireframe===!1,sizeAttenuation:f.sizeAttenuation===!0,logarithmicDepthBuffer:u,reversedDepthBuffer:be,skinning:S.isSkinnedMesh===!0,morphTargets:R.morphAttributes.position!==void 0,morphNormals:R.morphAttributes.normal!==void 0,morphColors:R.morphAttributes.color!==void 0,morphTargetsCount:V,morphTextureStride:me,numDirLights:v.directional.length,numPointLights:v.point.length,numSpotLights:v.spot.length,numSpotLightMaps:v.spotLightMap.length,numRectAreaLights:v.rectArea.length,numHemiLights:v.hemi.length,numDirLightShadows:v.directionalShadowMap.length,numPointLightShadows:v.pointShadowMap.length,numSpotLightShadows:v.spotShadowMap.length,numSpotLightShadowsWithMaps:v.numSpotLightShadowsWithMaps,numLightProbes:v.numLightProbes,numClippingPlanes:s.numPlanes,numClipIntersection:s.numIntersection,dithering:f.dithering,shadowMapEnabled:i.shadowMap.enabled&&_.length>0,shadowMapType:i.shadowMap.type,toneMapping:N,decodeVideoTexture:Ne&&f.map.isVideoTexture===!0&&ht.getTransfer(f.map.colorSpace)===dt,decodeVideoTextureEmissive:H&&f.emissiveMap.isVideoTexture===!0&&ht.getTransfer(f.emissiveMap.colorSpace)===dt,premultipliedAlpha:f.premultipliedAlpha,doubleSided:f.side===It,flipSided:f.side===Xt,useDepthPacking:f.depthPacking>=0,depthPacking:f.depthPacking||0,index0AttributeName:f.index0AttributeName,extensionClipCullDistance:Et&&f.extensions.clipCullDistance===!0&&n.has("WEBGL_clip_cull_distance"),extensionMultiDraw:(Et&&f.extensions.multiDraw===!0||Ie)&&n.has("WEBGL_multi_draw"),rendererExtensionParallelShaderCompile:n.has("KHR_parallel_shader_compile"),customProgramCacheKey:f.customProgramCacheKey()};return ut.vertexUv1s=l.has(1),ut.vertexUv2s=l.has(2),ut.vertexUv3s=l.has(3),l.clear(),ut},getProgramCacheKey:function(f){let v=[];if(f.shaderID?v.push(f.shaderID):(v.push(f.customVertexShaderID),v.push(f.customFragmentShaderID)),f.defines!==void 0)for(let _ in f.defines)v.push(_),v.push(f.defines[_]);return f.isRawShaderMaterial===!1&&((function(_,y){_.push(y.precision),_.push(y.outputColorSpace),_.push(y.envMapMode),_.push(y.envMapCubeUVHeight),_.push(y.mapUv),_.push(y.alphaMapUv),_.push(y.lightMapUv),_.push(y.aoMapUv),_.push(y.bumpMapUv),_.push(y.normalMapUv),_.push(y.displacementMapUv),_.push(y.emissiveMapUv),_.push(y.metalnessMapUv),_.push(y.roughnessMapUv),_.push(y.anisotropyMapUv),_.push(y.clearcoatMapUv),_.push(y.clearcoatNormalMapUv),_.push(y.clearcoatRoughnessMapUv),_.push(y.iridescenceMapUv),_.push(y.iridescenceThicknessMapUv),_.push(y.sheenColorMapUv),_.push(y.sheenRoughnessMapUv),_.push(y.specularMapUv),_.push(y.specularColorMapUv),_.push(y.specularIntensityMapUv),_.push(y.transmissionMapUv),_.push(y.thicknessMapUv),_.push(y.combine),_.push(y.fogExp2),_.push(y.sizeAttenuation),_.push(y.morphTargetsCount),_.push(y.morphAttributeCount),_.push(y.numDirLights),_.push(y.numPointLights),_.push(y.numSpotLights),_.push(y.numSpotLightMaps),_.push(y.numHemiLights),_.push(y.numRectAreaLights),_.push(y.numDirLightShadows),_.push(y.numPointLightShadows),_.push(y.numSpotLightShadows),_.push(y.numSpotLightShadowsWithMaps),_.push(y.numLightProbes),_.push(y.shadowMapType),_.push(y.toneMapping),_.push(y.numClippingPlanes),_.push(y.numClipIntersection),_.push(y.depthPacking)})(v,f),(function(_,y){o.disableAll(),y.supportsVertexTextures&&o.enable(0),y.instancing&&o.enable(1),y.instancingColor&&o.enable(2),y.instancingMorph&&o.enable(3),y.matcap&&o.enable(4),y.envMap&&o.enable(5),y.normalMapObjectSpace&&o.enable(6),y.normalMapTangentSpace&&o.enable(7),y.clearcoat&&o.enable(8),y.iridescence&&o.enable(9),y.alphaTest&&o.enable(10),y.vertexColors&&o.enable(11),y.vertexAlphas&&o.enable(12),y.vertexUv1s&&o.enable(13),y.vertexUv2s&&o.enable(14),y.vertexUv3s&&o.enable(15),y.vertexTangents&&o.enable(16),y.anisotropy&&o.enable(17),y.alphaHash&&o.enable(18),y.batching&&o.enable(19),y.dispersion&&o.enable(20),y.batchingColor&&o.enable(21),y.gradientMap&&o.enable(22),_.push(o.mask),o.disableAll(),y.fog&&o.enable(0),y.useFog&&o.enable(1),y.flatShading&&o.enable(2),y.logarithmicDepthBuffer&&o.enable(3),y.reversedDepthBuffer&&o.enable(4),y.skinning&&o.enable(5),y.morphTargets&&o.enable(6),y.morphNormals&&o.enable(7),y.morphColors&&o.enable(8),y.premultipliedAlpha&&o.enable(9),y.shadowMapEnabled&&o.enable(10),y.doubleSided&&o.enable(11),y.flipSided&&o.enable(12),y.useDepthPacking&&o.enable(13),y.dithering&&o.enable(14),y.transmission&&o.enable(15),y.sheen&&o.enable(16),y.opaque&&o.enable(17),y.pointsUvs&&o.enable(18),y.decodeVideoTexture&&o.enable(19),y.decodeVideoTextureEmissive&&o.enable(20),y.alphaToCoverage&&o.enable(21),_.push(o.mask)})(v,f),v.push(i.outputColorSpace)),v.push(f.customProgramCacheKey),v.join()},getUniforms:function(f){let v=m[f.type],_;if(v){let y=hi[v];_=sd.clone(y.uniforms)}else _=f.uniforms;return _},acquireProgram:function(f,v){let _;for(let y=0,S=h.length;y<S;y++){let w=h[y];if(w.cacheKey===v){_=w,++_.usedTimes;break}}return _===void 0&&(_=new im(i,v,f,a),h.push(_)),_},releaseProgram:function(f){if(--f.usedTimes===0){let v=h.indexOf(f);h[v]=h[h.length-1],h.pop(),f.destroy()}},releaseShaderCache:function(f){c.remove(f)},programs:h,dispose:function(){c.dispose()}}}function sm(){let i=new WeakMap;return{has:function(e){return i.has(e)},get:function(e){let t=i.get(e);return t===void 0&&(t={},i.set(e,t)),t},remove:function(e){i.delete(e)},update:function(e,t,n){i.get(e)[t]=n},dispose:function(){i=new WeakMap}}}function om(i,e){return i.groupOrder!==e.groupOrder?i.groupOrder-e.groupOrder:i.renderOrder!==e.renderOrder?i.renderOrder-e.renderOrder:i.material.id!==e.material.id?i.material.id-e.material.id:i.z!==e.z?i.z-e.z:i.id-e.id}function Id(i,e){return i.groupOrder!==e.groupOrder?i.groupOrder-e.groupOrder:i.renderOrder!==e.renderOrder?i.renderOrder-e.renderOrder:i.z!==e.z?e.z-i.z:i.id-e.id}function Ld(){let i=[],e=0,t=[],n=[],r=[];function a(s,o,c,l,h,u){let d=i[e];return d===void 0?(d={id:s.id,object:s,geometry:o,material:c,groupOrder:l,renderOrder:s.renderOrder,z:h,group:u},i[e]=d):(d.id=s.id,d.object=s,d.geometry=o,d.material=c,d.groupOrder=l,d.renderOrder=s.renderOrder,d.z=h,d.group=u),e++,d}return{opaque:t,transmissive:n,transparent:r,init:function(){e=0,t.length=0,n.length=0,r.length=0},push:function(s,o,c,l,h,u){let d=a(s,o,c,l,h,u);c.transmission>0?n.push(d):c.transparent===!0?r.push(d):t.push(d)},unshift:function(s,o,c,l,h,u){let d=a(s,o,c,l,h,u);c.transmission>0?n.unshift(d):c.transparent===!0?r.unshift(d):t.unshift(d)},finish:function(){for(let s=e,o=i.length;s<o;s++){let c=i[s];if(c.id===null)break;c.id=null,c.object=null,c.geometry=null,c.material=null,c.group=null}},sort:function(s,o){t.length>1&&t.sort(s||om),n.length>1&&n.sort(o||Id),r.length>1&&r.sort(o||Id)}}}function lm(){let i=new WeakMap;return{get:function(e,t){let n=i.get(e),r;return n===void 0?(r=new Ld,i.set(e,[r])):t>=n.length?(r=new Ld,n.push(r)):r=n[t],r},dispose:function(){i=new WeakMap}}}function cm(){let i={};return{get:function(e){if(i[e.id]!==void 0)return i[e.id];let t;switch(e.type){case"DirectionalLight":t={direction:new E,color:new Ve};break;case"SpotLight":t={position:new E,direction:new E,color:new Ve,distance:0,coneCos:0,penumbraCos:0,decay:0};break;case"PointLight":t={position:new E,color:new Ve,distance:0,decay:0};break;case"HemisphereLight":t={direction:new E,skyColor:new Ve,groundColor:new Ve};break;case"RectAreaLight":t={color:new Ve,position:new E,halfWidth:new E,halfHeight:new E}}return i[e.id]=t,t}}}var hm=0;function um(i,e){return(e.castShadow?2:0)-(i.castShadow?2:0)+(e.map?1:0)-(i.map?1:0)}function dm(i){let e=new cm,t=(function(){let o={};return{get:function(c){if(o[c.id]!==void 0)return o[c.id];let l;switch(c.type){case"DirectionalLight":case"SpotLight":l={shadowIntensity:1,shadowBias:0,shadowNormalBias:0,shadowRadius:1,shadowMapSize:new pe};break;case"PointLight":l={shadowIntensity:1,shadowBias:0,shadowNormalBias:0,shadowRadius:1,shadowMapSize:new pe,shadowCameraNear:1,shadowCameraFar:1e3}}return o[c.id]=l,l}}})(),n={version:0,hash:{directionalLength:-1,pointLength:-1,spotLength:-1,rectAreaLength:-1,hemiLength:-1,numDirectionalShadows:-1,numPointShadows:-1,numSpotShadows:-1,numSpotMaps:-1,numLightProbes:-1},ambient:[0,0,0],probe:[],directional:[],directionalShadow:[],directionalShadowMap:[],directionalShadowMatrix:[],spot:[],spotLightMap:[],spotShadow:[],spotShadowMap:[],spotLightMatrix:[],rectArea:[],rectAreaLTC1:null,rectAreaLTC2:null,point:[],pointShadow:[],pointShadowMap:[],pointShadowMatrix:[],hemi:[],numSpotLightShadowsWithMaps:0,numLightProbes:0};for(let o=0;o<9;o++)n.probe.push(new E);let r=new E,a=new qe,s=new qe;return{setup:function(o){let c=0,l=0,h=0;for(let B=0;B<9;B++)n.probe[B].set(0,0,0);let u=0,d=0,p=0,m=0,g=0,f=0,v=0,_=0,y=0,S=0,w=0;o.sort(um);for(let B=0,G=o.length;B<G;B++){let D=o[B],J=D.color,K=D.intensity,V=D.distance,se=D.shadow&&D.shadow.map?D.shadow.map.texture:null;if(D.isAmbientLight)c+=J.r*K,l+=J.g*K,h+=J.b*K;else if(D.isLightProbe){for(let X=0;X<9;X++)n.probe[X].addScaledVector(D.sh.coefficients[X],K);w++}else if(D.isDirectionalLight){let X=e.get(D);if(X.color.copy(D.color).multiplyScalar(D.intensity),D.castShadow){let ee=D.shadow,Q=t.get(D);Q.shadowIntensity=ee.intensity,Q.shadowBias=ee.bias,Q.shadowNormalBias=ee.normalBias,Q.shadowRadius=ee.radius,Q.shadowMapSize=ee.mapSize,n.directionalShadow[u]=Q,n.directionalShadowMap[u]=se,n.directionalShadowMatrix[u]=D.shadow.matrix,f++}n.directional[u]=X,u++}else if(D.isSpotLight){let X=e.get(D);X.position.setFromMatrixPosition(D.matrixWorld),X.color.copy(J).multiplyScalar(K),X.distance=V,X.coneCos=Math.cos(D.angle),X.penumbraCos=Math.cos(D.angle*(1-D.penumbra)),X.decay=D.decay,n.spot[p]=X;let ee=D.shadow;if(D.map&&(n.spotLightMap[y]=D.map,y++,ee.updateMatrices(D),D.castShadow&&S++),n.spotLightMatrix[p]=ee.matrix,D.castShadow){let Q=t.get(D);Q.shadowIntensity=ee.intensity,Q.shadowBias=ee.bias,Q.shadowNormalBias=ee.normalBias,Q.shadowRadius=ee.radius,Q.shadowMapSize=ee.mapSize,n.spotShadow[p]=Q,n.spotShadowMap[p]=se,_++}p++}else if(D.isRectAreaLight){let X=e.get(D);X.color.copy(J).multiplyScalar(K),X.halfWidth.set(.5*D.width,0,0),X.halfHeight.set(0,.5*D.height,0),n.rectArea[m]=X,m++}else if(D.isPointLight){let X=e.get(D);if(X.color.copy(D.color).multiplyScalar(D.intensity),X.distance=D.distance,X.decay=D.decay,D.castShadow){let ee=D.shadow,Q=t.get(D);Q.shadowIntensity=ee.intensity,Q.shadowBias=ee.bias,Q.shadowNormalBias=ee.normalBias,Q.shadowRadius=ee.radius,Q.shadowMapSize=ee.mapSize,Q.shadowCameraNear=ee.camera.near,Q.shadowCameraFar=ee.camera.far,n.pointShadow[d]=Q,n.pointShadowMap[d]=se,n.pointShadowMatrix[d]=D.shadow.matrix,v++}n.point[d]=X,d++}else if(D.isHemisphereLight){let X=e.get(D);X.skyColor.copy(D.color).multiplyScalar(K),X.groundColor.copy(D.groundColor).multiplyScalar(K),n.hemi[g]=X,g++}}m>0&&(i.has("OES_texture_float_linear")===!0?(n.rectAreaLTC1=Ae.LTC_FLOAT_1,n.rectAreaLTC2=Ae.LTC_FLOAT_2):(n.rectAreaLTC1=Ae.LTC_HALF_1,n.rectAreaLTC2=Ae.LTC_HALF_2)),n.ambient[0]=c,n.ambient[1]=l,n.ambient[2]=h;let R=n.hash;R.directionalLength===u&&R.pointLength===d&&R.spotLength===p&&R.rectAreaLength===m&&R.hemiLength===g&&R.numDirectionalShadows===f&&R.numPointShadows===v&&R.numSpotShadows===_&&R.numSpotMaps===y&&R.numLightProbes===w||(n.directional.length=u,n.spot.length=p,n.rectArea.length=m,n.point.length=d,n.hemi.length=g,n.directionalShadow.length=f,n.directionalShadowMap.length=f,n.pointShadow.length=v,n.pointShadowMap.length=v,n.spotShadow.length=_,n.spotShadowMap.length=_,n.directionalShadowMatrix.length=f,n.pointShadowMatrix.length=v,n.spotLightMatrix.length=_+y-S,n.spotLightMap.length=y,n.numSpotLightShadowsWithMaps=S,n.numLightProbes=w,R.directionalLength=u,R.pointLength=d,R.spotLength=p,R.rectAreaLength=m,R.hemiLength=g,R.numDirectionalShadows=f,R.numPointShadows=v,R.numSpotShadows=_,R.numSpotMaps=y,R.numLightProbes=w,n.version=hm++)},setupView:function(o,c){let l=0,h=0,u=0,d=0,p=0,m=c.matrixWorldInverse;for(let g=0,f=o.length;g<f;g++){let v=o[g];if(v.isDirectionalLight){let _=n.directional[l];_.direction.setFromMatrixPosition(v.matrixWorld),r.setFromMatrixPosition(v.target.matrixWorld),_.direction.sub(r),_.direction.transformDirection(m),l++}else if(v.isSpotLight){let _=n.spot[u];_.position.setFromMatrixPosition(v.matrixWorld),_.position.applyMatrix4(m),_.direction.setFromMatrixPosition(v.matrixWorld),r.setFromMatrixPosition(v.target.matrixWorld),_.direction.sub(r),_.direction.transformDirection(m),u++}else if(v.isRectAreaLight){let _=n.rectArea[d];_.position.setFromMatrixPosition(v.matrixWorld),_.position.applyMatrix4(m),s.identity(),a.copy(v.matrixWorld),a.premultiply(m),s.extractRotation(a),_.halfWidth.set(.5*v.width,0,0),_.halfHeight.set(0,.5*v.height,0),_.halfWidth.applyMatrix4(s),_.halfHeight.applyMatrix4(s),d++}else if(v.isPointLight){let _=n.point[h];_.position.setFromMatrixPosition(v.matrixWorld),_.position.applyMatrix4(m),h++}else if(v.isHemisphereLight){let _=n.hemi[p];_.direction.setFromMatrixPosition(v.matrixWorld),_.direction.transformDirection(m),p++}}},state:n}}function Dd(i){let e=new dm(i),t=[],n=[],r={lightsArray:t,shadowsArray:n,camera:null,lights:e,transmissionRenderTarget:{}};return{init:function(a){r.camera=a,t.length=0,n.length=0},state:r,setupLights:function(){e.setup(t)},setupLightsView:function(a){e.setupView(t,a)},pushLight:function(a){t.push(a)},pushShadow:function(a){n.push(a)}}}function pm(i){let e=new WeakMap;return{get:function(t,n=0){let r=e.get(t),a;return r===void 0?(a=new Dd(i),e.set(t,[a])):n>=r.length?(a=new Dd(i),r.push(a)):a=r[n],a},dispose:function(){e=new WeakMap}}}function fm(i,e,t){let n=new qi,r=new pe,a=new pe,s=new xt,o=new To({depthPacking:qu}),c=new Eo,l={},h=t.maxTextureSize,u={[oi]:Xt,[Xt]:oi,[It]:It},d=new Dt({defines:{VSM_SAMPLES:8},uniforms:{shadow_pass:{value:null},resolution:{value:new pe},radius:{value:4}},vertexShader:`void main() {
	gl_Position = vec4( position, 1.0 );
}`,fragmentShader:`uniform sampler2D shadow_pass;
uniform vec2 resolution;
uniform float radius;
#include <packing>
void main() {
	const float samples = float( VSM_SAMPLES );
	float mean = 0.0;
	float squared_mean = 0.0;
	float uvStride = samples <= 1.0 ? 0.0 : 2.0 / ( samples - 1.0 );
	float uvStart = samples <= 1.0 ? 0.0 : - 1.0;
	for ( float i = 0.0; i < samples; i ++ ) {
		float uvOffset = uvStart + i * uvStride;
		#ifdef HORIZONTAL_PASS
			vec2 distribution = unpackRGBATo2Half( texture2D( shadow_pass, ( gl_FragCoord.xy + vec2( uvOffset, 0.0 ) * radius ) / resolution ) );
			mean += distribution.x;
			squared_mean += distribution.y * distribution.y + distribution.x * distribution.x;
		#else
			float depth = unpackRGBAToDepth( texture2D( shadow_pass, ( gl_FragCoord.xy + vec2( 0.0, uvOffset ) * radius ) / resolution ) );
			mean += depth;
			squared_mean += depth * depth;
		#endif
	}
	mean = mean / samples;
	squared_mean = squared_mean / samples;
	float std_dev = sqrt( squared_mean - mean * mean );
	gl_FragColor = pack2HalfToRGBA( vec2( mean, std_dev ) );
}`}),p=d.clone();p.defines.HORIZONTAL_PASS=1;let m=new mt;m.setAttribute("position",new pt(new Float32Array([-1,-1,.5,3,-1,.5,-1,3,.5]),3));let g=new Le(m,d),f=this;this.enabled=!1,this.autoUpdate=!0,this.needsUpdate=!1,this.type=oc;let v=this.type;function _(R,B){let G=e.update(g);d.defines.VSM_SAMPLES!==R.blurSamples&&(d.defines.VSM_SAMPLES=R.blurSamples,p.defines.VSM_SAMPLES=R.blurSamples,d.needsUpdate=!0,p.needsUpdate=!0),R.mapPass===null&&(R.mapPass=new yn(r.x,r.y)),d.uniforms.shadow_pass.value=R.map.texture,d.uniforms.resolution.value=R.mapSize,d.uniforms.radius.value=R.radius,i.setRenderTarget(R.mapPass),i.clear(),i.renderBufferDirect(B,null,G,d,g,null),p.uniforms.shadow_pass.value=R.mapPass.texture,p.uniforms.resolution.value=R.mapSize,p.uniforms.radius.value=R.radius,i.setRenderTarget(R.map),i.clear(),i.renderBufferDirect(B,null,G,p,g,null)}function y(R,B,G,D){let J=null,K=G.isPointLight===!0?R.customDistanceMaterial:R.customDepthMaterial;if(K!==void 0)J=K;else if(J=G.isPointLight===!0?c:o,i.localClippingEnabled&&B.clipShadows===!0&&Array.isArray(B.clippingPlanes)&&B.clippingPlanes.length!==0||B.displacementMap&&B.displacementScale!==0||B.alphaMap&&B.alphaTest>0||B.map&&B.alphaTest>0||B.alphaToCoverage===!0){let V=J.uuid,se=B.uuid,X=l[V];X===void 0&&(X={},l[V]=X);let ee=X[se];ee===void 0&&(ee=J.clone(),X[se]=ee,B.addEventListener("dispose",w)),J=ee}return J.visible=B.visible,J.wireframe=B.wireframe,J.side=D===si?B.shadowSide!==null?B.shadowSide:B.side:B.shadowSide!==null?B.shadowSide:u[B.side],J.alphaMap=B.alphaMap,J.alphaTest=B.alphaToCoverage===!0?.5:B.alphaTest,J.map=B.map,J.clipShadows=B.clipShadows,J.clippingPlanes=B.clippingPlanes,J.clipIntersection=B.clipIntersection,J.displacementMap=B.displacementMap,J.displacementScale=B.displacementScale,J.displacementBias=B.displacementBias,J.wireframeLinewidth=B.wireframeLinewidth,J.linewidth=B.linewidth,G.isPointLight===!0&&J.isMeshDistanceMaterial===!0&&(i.properties.get(J).light=G),J}function S(R,B,G,D,J){if(R.visible===!1)return;if(R.layers.test(B.layers)&&(R.isMesh||R.isLine||R.isPoints)&&(R.castShadow||R.receiveShadow&&J===si)&&(!R.frustumCulled||n.intersectsObject(R))){R.modelViewMatrix.multiplyMatrices(G.matrixWorldInverse,R.matrixWorld);let V=e.update(R),se=R.material;if(Array.isArray(se)){let X=V.groups;for(let ee=0,Q=X.length;ee<Q;ee++){let me=X[ee],ae=se[me.materialIndex];if(ae&&ae.visible){let be=y(R,ae,D,J);R.onBeforeShadow(i,R,B,G,V,be,me),i.renderBufferDirect(G,null,V,be,R,me),R.onAfterShadow(i,R,B,G,V,be,me)}}}else if(se.visible){let X=y(R,se,D,J);R.onBeforeShadow(i,R,B,G,V,X,null),i.renderBufferDirect(G,null,V,X,R,null),R.onAfterShadow(i,R,B,G,V,X,null)}}let K=R.children;for(let V=0,se=K.length;V<se;V++)S(K[V],B,G,D,J)}function w(R){R.target.removeEventListener("dispose",w);for(let B in l){let G=l[B],D=R.target.uuid;D in G&&(G[D].dispose(),delete G[D])}}this.render=function(R,B,G){if(f.enabled===!1||f.autoUpdate===!1&&f.needsUpdate===!1||R.length===0)return;let D=i.getRenderTarget(),J=i.getActiveCubeFace(),K=i.getActiveMipmapLevel(),V=i.state;V.setBlending(li),V.buffers.depth.getReversed()===!0?V.buffers.color.setClear(0,0,0,0):V.buffers.color.setClear(1,1,1,1),V.buffers.depth.setTest(!0),V.setScissorTest(!1);let se=v!==si&&this.type===si,X=v===si&&this.type!==si;for(let ee=0,Q=R.length;ee<Q;ee++){let me=R[ee],ae=me.shadow;if(ae===void 0){console.warn("THREE.WebGLShadowMap:",me,"has no shadow.");continue}if(ae.autoUpdate===!1&&ae.needsUpdate===!1)continue;r.copy(ae.mapSize);let be=ae.getFrameExtents();if(r.multiply(be),a.copy(ae.mapSize),(r.x>h||r.y>h)&&(r.x>h&&(a.x=Math.floor(h/be.x),r.x=a.x*be.x,ae.mapSize.x=a.x),r.y>h&&(a.y=Math.floor(h/be.y),r.y=a.y*be.y,ae.mapSize.y=a.y)),ae.map===null||se===!0||X===!0){let Ie=this.type!==si?{minFilter:ii,magFilter:ii}:{};ae.map!==null&&ae.map.dispose(),ae.map=new yn(r.x,r.y,Ie),ae.map.texture.name=me.name+".shadowMap",ae.camera.updateProjectionMatrix()}i.setRenderTarget(ae.map),i.clear();let Be=ae.getViewportCount();for(let Ie=0;Ie<Be;Ie++){let Ne=ae.getViewport(Ie);s.set(a.x*Ne.x,a.y*Ne.y,a.x*Ne.z,a.y*Ne.w),V.viewport(s),ae.updateMatrices(me,Ie),n=ae.getFrustum(),S(B,G,ae.camera,me,this.type)}ae.isPointLightShadow!==!0&&this.type===si&&_(ae,G),ae.needsUpdate=!1}v=this.type,f.needsUpdate=!1,i.setRenderTarget(D,J,K)}}var mm={[Fo]:Oo,[Bo]:Ho,[ko]:Go,[ss]:zo,[Oo]:Fo,[Ho]:Bo,[Go]:ko,[zo]:ss};function gm(i,e){let t=new function(){let M=!1,A=new xt,F=null,P=new xt(0,0,0,0);return{setMask:function(te){F===te||M||(i.colorMask(te,te,te,te),F=te)},setLocked:function(te){M=te},setClear:function(te,j,q,he,Se){Se===!0&&(te*=he,j*=he,q*=he),A.set(te,j,q,he),P.equals(A)===!1&&(i.clearColor(te,j,q,he),P.copy(A))},reset:function(){M=!1,F=null,P.set(-1,0,0,0)}}},n=new function(){let M=!1,A=!1,F=null,P=null,te=null;return{setReversed:function(j){if(A!==j){let q=e.get("EXT_clip_control");j?q.clipControlEXT(q.LOWER_LEFT_EXT,q.ZERO_TO_ONE_EXT):q.clipControlEXT(q.LOWER_LEFT_EXT,q.NEGATIVE_ONE_TO_ONE_EXT),A=j;let he=te;te=null,this.setClear(he)}},getReversed:function(){return A},setTest:function(j){j?re(i.DEPTH_TEST):ne(i.DEPTH_TEST)},setMask:function(j){F===j||M||(i.depthMask(j),F=j)},setFunc:function(j){if(A&&(j=mm[j]),P!==j){switch(j){case Fo:i.depthFunc(i.NEVER);break;case Oo:i.depthFunc(i.ALWAYS);break;case Bo:i.depthFunc(i.LESS);break;case ss:i.depthFunc(i.LEQUAL);break;case ko:i.depthFunc(i.EQUAL);break;case zo:i.depthFunc(i.GEQUAL);break;case Ho:i.depthFunc(i.GREATER);break;case Go:i.depthFunc(i.NOTEQUAL);break;default:i.depthFunc(i.LEQUAL)}P=j}},setLocked:function(j){M=j},setClear:function(j){te!==j&&(A&&(j=1-j),i.clearDepth(j),te=j)},reset:function(){M=!1,F=null,P=null,te=null,A=!1}}},r=new function(){let M=!1,A=null,F=null,P=null,te=null,j=null,q=null,he=null,Se=null;return{setTest:function(ue){M||(ue?re(i.STENCIL_TEST):ne(i.STENCIL_TEST))},setMask:function(ue){A===ue||M||(i.stencilMask(ue),A=ue)},setFunc:function(ue,Re,De){F===ue&&P===Re&&te===De||(i.stencilFunc(ue,Re,De),F=ue,P=Re,te=De)},setOp:function(ue,Re,De){j===ue&&q===Re&&he===De||(i.stencilOp(ue,Re,De),j=ue,q=Re,he=De)},setLocked:function(ue){M=ue},setClear:function(ue){Se!==ue&&(i.clearStencil(ue),Se=ue)},reset:function(){M=!1,A=null,F=null,P=null,te=null,j=null,q=null,he=null,Se=null}}},a=new WeakMap,s=new WeakMap,o={},c={},l=new WeakMap,h=[],u=null,d=!1,p=null,m=null,g=null,f=null,v=null,_=null,y=null,S=new Ve(0,0,0),w=0,R=!1,B=null,G=null,D=null,J=null,K=null,V=i.getParameter(i.MAX_COMBINED_TEXTURE_IMAGE_UNITS),se=!1,X=0,ee=i.getParameter(i.VERSION);ee.indexOf("WebGL")!==-1?(X=parseFloat(/^WebGL (\d)/.exec(ee)[1]),se=X>=1):ee.indexOf("OpenGL ES")!==-1&&(X=parseFloat(/^OpenGL ES (\d)/.exec(ee)[1]),se=X>=2);let Q=null,me={},ae=i.getParameter(i.SCISSOR_BOX),be=i.getParameter(i.VIEWPORT),Be=new xt().fromArray(ae),Ie=new xt().fromArray(be);function Ne(M,A,F,P){let te=new Uint8Array(4),j=i.createTexture();i.bindTexture(M,j),i.texParameteri(M,i.TEXTURE_MIN_FILTER,i.NEAREST),i.texParameteri(M,i.TEXTURE_MAG_FILTER,i.NEAREST);for(let q=0;q<F;q++)M===i.TEXTURE_3D||M===i.TEXTURE_2D_ARRAY?i.texImage3D(A,0,i.RGBA,1,1,P,0,i.RGBA,i.UNSIGNED_BYTE,te):i.texImage2D(A+q,0,i.RGBA,1,1,0,i.RGBA,i.UNSIGNED_BYTE,te);return j}let le={};function re(M){o[M]!==!0&&(i.enable(M),o[M]=!0)}function ne(M){o[M]!==!1&&(i.disable(M),o[M]=!1)}le[i.TEXTURE_2D]=Ne(i.TEXTURE_2D,i.TEXTURE_2D,1),le[i.TEXTURE_CUBE_MAP]=Ne(i.TEXTURE_CUBE_MAP,i.TEXTURE_CUBE_MAP_POSITIVE_X,6),le[i.TEXTURE_2D_ARRAY]=Ne(i.TEXTURE_2D_ARRAY,i.TEXTURE_2D_ARRAY,1,1),le[i.TEXTURE_3D]=Ne(i.TEXTURE_3D,i.TEXTURE_3D,1,1),t.setClear(0,0,0,1),n.setClear(1),r.setClear(0),re(i.DEPTH_TEST),n.setFunc(ss),b(!1),H(sc),re(i.CULL_FACE),T(li);let Oe={[oa]:i.FUNC_ADD,[mu]:i.FUNC_SUBTRACT,[gu]:i.FUNC_REVERSE_SUBTRACT};Oe[vu]=i.MIN,Oe[_u]=i.MAX;let Ge={[yu]:i.ZERO,[xu]:i.ONE,[Mu]:i.SRC_COLOR,[bu]:i.SRC_ALPHA,[Cu]:i.SRC_ALPHA_SATURATE,[Au]:i.DST_COLOR,[Eu]:i.DST_ALPHA,[Su]:i.ONE_MINUS_SRC_COLOR,[Tu]:i.ONE_MINUS_SRC_ALPHA,[Ru]:i.ONE_MINUS_DST_COLOR,[wu]:i.ONE_MINUS_DST_ALPHA,[Pu]:i.CONSTANT_COLOR,[Iu]:i.ONE_MINUS_CONSTANT_COLOR,[Lu]:i.CONSTANT_ALPHA,[Du]:i.ONE_MINUS_CONSTANT_ALPHA};function T(M,A,F,P,te,j,q,he,Se,ue){if(M!==li){if(d===!1&&(re(i.BLEND),d=!0),M===fu)te=te||A,j=j||F,q=q||P,A===m&&te===v||(i.blendEquationSeparate(Oe[A],Oe[te]),m=A,v=te),F===g&&P===f&&j===_&&q===y||(i.blendFuncSeparate(Ge[F],Ge[P],Ge[j],Ge[q]),g=F,f=P,_=j,y=q),he.equals(S)!==!1&&Se===w||(i.blendColor(he.r,he.g,he.b,Se),S.copy(he),w=Se),p=M,R=!1;else if(M!==p||ue!==R){if(m===oa&&v===oa||(i.blendEquation(i.FUNC_ADD),m=oa,v=oa),ue)switch(M){case _r:i.blendFuncSeparate(i.ONE,i.ONE_MINUS_SRC_ALPHA,i.ONE,i.ONE_MINUS_SRC_ALPHA);break;case Xn:i.blendFunc(i.ONE,i.ONE);break;case lc:i.blendFuncSeparate(i.ZERO,i.ONE_MINUS_SRC_COLOR,i.ZERO,i.ONE);break;case cc:i.blendFuncSeparate(i.DST_COLOR,i.ONE_MINUS_SRC_ALPHA,i.ZERO,i.ONE);break;default:console.error("THREE.WebGLState: Invalid blending: ",M)}else switch(M){case _r:i.blendFuncSeparate(i.SRC_ALPHA,i.ONE_MINUS_SRC_ALPHA,i.ONE,i.ONE_MINUS_SRC_ALPHA);break;case Xn:i.blendFuncSeparate(i.SRC_ALPHA,i.ONE,i.ONE,i.ONE);break;case lc:console.error("THREE.WebGLState: SubtractiveBlending requires material.premultipliedAlpha = true");break;case cc:console.error("THREE.WebGLState: MultiplyBlending requires material.premultipliedAlpha = true");break;default:console.error("THREE.WebGLState: Invalid blending: ",M)}g=null,f=null,_=null,y=null,S.set(0,0,0),w=0,p=M,R=ue}}else d===!0&&(ne(i.BLEND),d=!1)}function b(M){B!==M&&(M?i.frontFace(i.CW):i.frontFace(i.CCW),B=M)}function H(M){M!==uu?(re(i.CULL_FACE),M!==G&&(M===sc?i.cullFace(i.BACK):M===du?i.cullFace(i.FRONT):i.cullFace(i.FRONT_AND_BACK))):ne(i.CULL_FACE),G=M}function U(M,A,F){M?(re(i.POLYGON_OFFSET_FILL),J===A&&K===F||(i.polygonOffset(A,F),J=A,K=F)):ne(i.POLYGON_OFFSET_FILL)}return{buffers:{color:t,depth:n,stencil:r},enable:re,disable:ne,bindFramebuffer:function(M,A){return c[M]!==A&&(i.bindFramebuffer(M,A),c[M]=A,M===i.DRAW_FRAMEBUFFER&&(c[i.FRAMEBUFFER]=A),M===i.FRAMEBUFFER&&(c[i.DRAW_FRAMEBUFFER]=A),!0)},drawBuffers:function(M,A){let F=h,P=!1;if(M){F=l.get(A),F===void 0&&(F=[],l.set(A,F));let te=M.textures;if(F.length!==te.length||F[0]!==i.COLOR_ATTACHMENT0){for(let j=0,q=te.length;j<q;j++)F[j]=i.COLOR_ATTACHMENT0+j;F.length=te.length,P=!0}}else F[0]!==i.BACK&&(F[0]=i.BACK,P=!0);P&&i.drawBuffers(F)},useProgram:function(M){return u!==M&&(i.useProgram(M),u=M,!0)},setBlending:T,setMaterial:function(M,A){M.side===It?ne(i.CULL_FACE):re(i.CULL_FACE);let F=M.side===Xt;A&&(F=!F),b(F),M.blending===_r&&M.transparent===!1?T(li):T(M.blending,M.blendEquation,M.blendSrc,M.blendDst,M.blendEquationAlpha,M.blendSrcAlpha,M.blendDstAlpha,M.blendColor,M.blendAlpha,M.premultipliedAlpha),n.setFunc(M.depthFunc),n.setTest(M.depthTest),n.setMask(M.depthWrite),t.setMask(M.colorWrite);let P=M.stencilWrite;r.setTest(P),P&&(r.setMask(M.stencilWriteMask),r.setFunc(M.stencilFunc,M.stencilRef,M.stencilFuncMask),r.setOp(M.stencilFail,M.stencilZFail,M.stencilZPass)),U(M.polygonOffset,M.polygonOffsetFactor,M.polygonOffsetUnits),M.alphaToCoverage===!0?re(i.SAMPLE_ALPHA_TO_COVERAGE):ne(i.SAMPLE_ALPHA_TO_COVERAGE)},setFlipSided:b,setCullFace:H,setLineWidth:function(M){M!==D&&(se&&i.lineWidth(M),D=M)},setPolygonOffset:U,setScissorTest:function(M){M?re(i.SCISSOR_TEST):ne(i.SCISSOR_TEST)},activeTexture:function(M){M===void 0&&(M=i.TEXTURE0+V-1),Q!==M&&(i.activeTexture(M),Q=M)},bindTexture:function(M,A,F){F===void 0&&(F=Q===null?i.TEXTURE0+V-1:Q);let P=me[F];P===void 0&&(P={type:void 0,texture:void 0},me[F]=P),P.type===M&&P.texture===A||(Q!==F&&(i.activeTexture(F),Q=F),i.bindTexture(M,A||le[M]),P.type=M,P.texture=A)},unbindTexture:function(){let M=me[Q];M!==void 0&&M.type!==void 0&&(i.bindTexture(M.type,null),M.type=void 0,M.texture=void 0)},compressedTexImage2D:function(){try{i.compressedTexImage2D(...arguments)}catch(M){console.error("THREE.WebGLState:",M)}},compressedTexImage3D:function(){try{i.compressedTexImage3D(...arguments)}catch(M){console.error("THREE.WebGLState:",M)}},texImage2D:function(){try{i.texImage2D(...arguments)}catch(M){console.error("THREE.WebGLState:",M)}},texImage3D:function(){try{i.texImage3D(...arguments)}catch(M){console.error("THREE.WebGLState:",M)}},updateUBOMapping:function(M,A){let F=s.get(A);F===void 0&&(F=new WeakMap,s.set(A,F));let P=F.get(M);P===void 0&&(P=i.getUniformBlockIndex(A,M.name),F.set(M,P))},uniformBlockBinding:function(M,A){let F=s.get(A).get(M);a.get(A)!==F&&(i.uniformBlockBinding(A,F,M.__bindingPointIndex),a.set(A,F))},texStorage2D:function(){try{i.texStorage2D(...arguments)}catch(M){console.error("THREE.WebGLState:",M)}},texStorage3D:function(){try{i.texStorage3D(...arguments)}catch(M){console.error("THREE.WebGLState:",M)}},texSubImage2D:function(){try{i.texSubImage2D(...arguments)}catch(M){console.error("THREE.WebGLState:",M)}},texSubImage3D:function(){try{i.texSubImage3D(...arguments)}catch(M){console.error("THREE.WebGLState:",M)}},compressedTexSubImage2D:function(){try{i.compressedTexSubImage2D(...arguments)}catch(M){console.error("THREE.WebGLState:",M)}},compressedTexSubImage3D:function(){try{i.compressedTexSubImage3D(...arguments)}catch(M){console.error("THREE.WebGLState:",M)}},scissor:function(M){Be.equals(M)===!1&&(i.scissor(M.x,M.y,M.z,M.w),Be.copy(M))},viewport:function(M){Ie.equals(M)===!1&&(i.viewport(M.x,M.y,M.z,M.w),Ie.copy(M))},reset:function(){i.disable(i.BLEND),i.disable(i.CULL_FACE),i.disable(i.DEPTH_TEST),i.disable(i.POLYGON_OFFSET_FILL),i.disable(i.SCISSOR_TEST),i.disable(i.STENCIL_TEST),i.disable(i.SAMPLE_ALPHA_TO_COVERAGE),i.blendEquation(i.FUNC_ADD),i.blendFunc(i.ONE,i.ZERO),i.blendFuncSeparate(i.ONE,i.ZERO,i.ONE,i.ZERO),i.blendColor(0,0,0,0),i.colorMask(!0,!0,!0,!0),i.clearColor(0,0,0,0),i.depthMask(!0),i.depthFunc(i.LESS),n.setReversed(!1),i.clearDepth(1),i.stencilMask(4294967295),i.stencilFunc(i.ALWAYS,0,4294967295),i.stencilOp(i.KEEP,i.KEEP,i.KEEP),i.clearStencil(0),i.cullFace(i.BACK),i.frontFace(i.CCW),i.polygonOffset(0,0),i.activeTexture(i.TEXTURE0),i.bindFramebuffer(i.FRAMEBUFFER,null),i.bindFramebuffer(i.DRAW_FRAMEBUFFER,null),i.bindFramebuffer(i.READ_FRAMEBUFFER,null),i.useProgram(null),i.lineWidth(1),i.scissor(0,0,i.canvas.width,i.canvas.height),i.viewport(0,0,i.canvas.width,i.canvas.height),o={},Q=null,me={},c={},l=new WeakMap,h=[],u=null,d=!1,p=null,m=null,g=null,f=null,v=null,_=null,y=null,S=new Ve(0,0,0),w=0,R=!1,B=null,G=null,D=null,J=null,K=null,Be.set(0,0,i.canvas.width,i.canvas.height),Ie.set(0,0,i.canvas.width,i.canvas.height),t.reset(),n.reset(),r.reset()}}}function vm(i,e,t,n,r,a,s){let o=e.has("WEBGL_multisampled_render_to_texture")?e.get("WEBGL_multisampled_render_to_texture"):null,c=typeof navigator!="undefined"&&/OculusBrowser/g.test(navigator.userAgent),l=new pe,h=new WeakMap,u,d=new WeakMap,p=!1;try{p=typeof OffscreenCanvas!="undefined"&&new OffscreenCanvas(1,1).getContext("2d")!==null}catch(T){}function m(T,b){return p?new OffscreenCanvas(T,b):Ba("canvas")}function g(T,b,H){let U=1,M=Ge(T);if((M.width>H||M.height>H)&&(U=H/Math.max(M.width,M.height)),U<1){if(typeof HTMLImageElement!="undefined"&&T instanceof HTMLImageElement||typeof HTMLCanvasElement!="undefined"&&T instanceof HTMLCanvasElement||typeof ImageBitmap!="undefined"&&T instanceof ImageBitmap||typeof VideoFrame!="undefined"&&T instanceof VideoFrame){let A=Math.floor(U*M.width),F=Math.floor(U*M.height);u===void 0&&(u=m(A,F));let P=b?m(A,F):u;return P.width=A,P.height=F,P.getContext("2d").drawImage(T,0,0,A,F),console.warn("THREE.WebGLRenderer: Texture has been resized from ("+M.width+"x"+M.height+") to ("+A+"x"+F+")."),P}return"data"in T&&console.warn("THREE.WebGLRenderer: Image in DataTexture is too big ("+M.width+"x"+M.height+")."),T}return T}function f(T){return T.generateMipmaps}function v(T){i.generateMipmap(T)}function _(T){return T.isWebGLCubeRenderTarget?i.TEXTURE_CUBE_MAP:T.isWebGL3DRenderTarget?i.TEXTURE_3D:T.isWebGLArrayRenderTarget||T.isCompressedArrayTexture?i.TEXTURE_2D_ARRAY:i.TEXTURE_2D}function y(T,b,H,U,M=!1){if(T!==null){if(i[T]!==void 0)return i[T];console.warn("THREE.WebGLRenderer: Attempt to use non-existing WebGL internal format '"+T+"'")}let A=b;if(b===i.RED&&(H===i.FLOAT&&(A=i.R32F),H===i.HALF_FLOAT&&(A=i.R16F),H===i.UNSIGNED_BYTE&&(A=i.R8)),b===i.RED_INTEGER&&(H===i.UNSIGNED_BYTE&&(A=i.R8UI),H===i.UNSIGNED_SHORT&&(A=i.R16UI),H===i.UNSIGNED_INT&&(A=i.R32UI),H===i.BYTE&&(A=i.R8I),H===i.SHORT&&(A=i.R16I),H===i.INT&&(A=i.R32I)),b===i.RG&&(H===i.FLOAT&&(A=i.RG32F),H===i.HALF_FLOAT&&(A=i.RG16F),H===i.UNSIGNED_BYTE&&(A=i.RG8)),b===i.RG_INTEGER&&(H===i.UNSIGNED_BYTE&&(A=i.RG8UI),H===i.UNSIGNED_SHORT&&(A=i.RG16UI),H===i.UNSIGNED_INT&&(A=i.RG32UI),H===i.BYTE&&(A=i.RG8I),H===i.SHORT&&(A=i.RG16I),H===i.INT&&(A=i.RG32I)),b===i.RGB_INTEGER&&(H===i.UNSIGNED_BYTE&&(A=i.RGB8UI),H===i.UNSIGNED_SHORT&&(A=i.RGB16UI),H===i.UNSIGNED_INT&&(A=i.RGB32UI),H===i.BYTE&&(A=i.RGB8I),H===i.SHORT&&(A=i.RGB16I),H===i.INT&&(A=i.RGB32I)),b===i.RGBA_INTEGER&&(H===i.UNSIGNED_BYTE&&(A=i.RGBA8UI),H===i.UNSIGNED_SHORT&&(A=i.RGBA16UI),H===i.UNSIGNED_INT&&(A=i.RGBA32UI),H===i.BYTE&&(A=i.RGBA8I),H===i.SHORT&&(A=i.RGBA16I),H===i.INT&&(A=i.RGBA32I)),b===i.RGB&&(H===i.UNSIGNED_INT_5_9_9_9_REV&&(A=i.RGB9_E5),H===i.UNSIGNED_INT_10F_11F_11F_REV&&(A=i.R11F_G11F_B10F)),b===i.RGBA){let F=M?Fa:ht.getTransfer(U);H===i.FLOAT&&(A=i.RGBA32F),H===i.HALF_FLOAT&&(A=i.RGBA16F),H===i.UNSIGNED_BYTE&&(A=F===dt?i.SRGB8_ALPHA8:i.RGBA8),H===i.UNSIGNED_SHORT_4_4_4_4&&(A=i.RGBA4),H===i.UNSIGNED_SHORT_5_5_5_1&&(A=i.RGB5_A1)}return A!==i.R16F&&A!==i.R32F&&A!==i.RG16F&&A!==i.RG32F&&A!==i.RGBA16F&&A!==i.RGBA32F||e.get("EXT_color_buffer_float"),A}function S(T,b){let H;return T?b===null||b===Mr||b===ua?H=i.DEPTH24_STENCIL8:b===jn?H=i.DEPTH32F_STENCIL8:b===ca&&(H=i.DEPTH24_STENCIL8,console.warn("DepthTexture: 16 bit depth attachment is not supported with stencil. Using 24-bit attachment.")):b===null||b===Mr||b===ua?H=i.DEPTH_COMPONENT24:b===jn?H=i.DEPTH_COMPONENT32F:b===ca&&(H=i.DEPTH_COMPONENT16),H}function w(T,b){return f(T)===!0||T.isFramebufferTexture&&T.minFilter!==ii&&T.minFilter!==ri?Math.log2(Math.max(b.width,b.height))+1:T.mipmaps!==void 0&&T.mipmaps.length>0?T.mipmaps.length:T.isCompressedTexture&&Array.isArray(T.image)?b.mipmaps.length:1}function R(T){let b=T.target;b.removeEventListener("dispose",R),(function(H){let U=n.get(H);if(U.__webglInit===void 0)return;let M=H.source,A=d.get(M);if(A){let F=A[U.__cacheKey];F.usedTimes--,F.usedTimes===0&&G(H),Object.keys(A).length===0&&d.delete(M)}n.remove(H)})(b),b.isVideoTexture&&h.delete(b)}function B(T){let b=T.target;b.removeEventListener("dispose",B),(function(H){let U=n.get(H);if(H.depthTexture&&(H.depthTexture.dispose(),n.remove(H.depthTexture)),H.isWebGLCubeRenderTarget)for(let A=0;A<6;A++){if(Array.isArray(U.__webglFramebuffer[A]))for(let F=0;F<U.__webglFramebuffer[A].length;F++)i.deleteFramebuffer(U.__webglFramebuffer[A][F]);else i.deleteFramebuffer(U.__webglFramebuffer[A]);U.__webglDepthbuffer&&i.deleteRenderbuffer(U.__webglDepthbuffer[A])}else{if(Array.isArray(U.__webglFramebuffer))for(let A=0;A<U.__webglFramebuffer.length;A++)i.deleteFramebuffer(U.__webglFramebuffer[A]);else i.deleteFramebuffer(U.__webglFramebuffer);if(U.__webglDepthbuffer&&i.deleteRenderbuffer(U.__webglDepthbuffer),U.__webglMultisampledFramebuffer&&i.deleteFramebuffer(U.__webglMultisampledFramebuffer),U.__webglColorRenderbuffer)for(let A=0;A<U.__webglColorRenderbuffer.length;A++)U.__webglColorRenderbuffer[A]&&i.deleteRenderbuffer(U.__webglColorRenderbuffer[A]);U.__webglDepthRenderbuffer&&i.deleteRenderbuffer(U.__webglDepthRenderbuffer)}let M=H.textures;for(let A=0,F=M.length;A<F;A++){let P=n.get(M[A]);P.__webglTexture&&(i.deleteTexture(P.__webglTexture),s.memory.textures--),n.remove(M[A])}n.remove(H)})(b)}function G(T){let b=n.get(T);i.deleteTexture(b.__webglTexture);let H=T.source;delete d.get(H)[b.__cacheKey],s.memory.textures--}let D=0;function J(T,b){let H=n.get(T);if(T.isVideoTexture&&(function(U){let M=s.render.frame;h.get(U)!==M&&(h.set(U,M),U.update())})(T),T.isRenderTargetTexture===!1&&T.isExternalTexture!==!0&&T.version>0&&H.__version!==T.version){let U=T.image;if(U===null)console.warn("THREE.WebGLRenderer: Texture marked for update but no image data found.");else{if(U.complete!==!1)return void me(H,T,b);console.warn("THREE.WebGLRenderer: Texture marked for update but image is incomplete")}}else T.isExternalTexture&&(H.__webglTexture=T.sourceTexture?T.sourceTexture:null);t.bindTexture(i.TEXTURE_2D,H.__webglTexture,i.TEXTURE0+b)}let K={[Xi]:i.REPEAT,[$r]:i.CLAMP_TO_EDGE,[Ys]:i.MIRRORED_REPEAT},V={[ii]:i.NEAREST,[Vu]:i.NEAREST_MIPMAP_NEAREST,[ls]:i.NEAREST_MIPMAP_LINEAR,[ri]:i.LINEAR,[jo]:i.LINEAR_MIPMAP_NEAREST,[xr]:i.LINEAR_MIPMAP_LINEAR},se={[Ju]:i.NEVER,[nd]:i.ALWAYS,[Ku]:i.LESS,[Xc]:i.LEQUAL,[$u]:i.EQUAL,[td]:i.GEQUAL,[Qu]:i.GREATER,[ed]:i.NOTEQUAL};function X(T,b){if(b.type!==jn||e.has("OES_texture_float_linear")!==!1||b.magFilter!==ri&&b.magFilter!==jo&&b.magFilter!==ls&&b.magFilter!==xr&&b.minFilter!==ri&&b.minFilter!==jo&&b.minFilter!==ls&&b.minFilter!==xr||console.warn("THREE.WebGLRenderer: Unable to use linear filtering with floating point textures. OES_texture_float_linear not supported on this device."),i.texParameteri(T,i.TEXTURE_WRAP_S,K[b.wrapS]),i.texParameteri(T,i.TEXTURE_WRAP_T,K[b.wrapT]),T!==i.TEXTURE_3D&&T!==i.TEXTURE_2D_ARRAY||i.texParameteri(T,i.TEXTURE_WRAP_R,K[b.wrapR]),i.texParameteri(T,i.TEXTURE_MAG_FILTER,V[b.magFilter]),i.texParameteri(T,i.TEXTURE_MIN_FILTER,V[b.minFilter]),b.compareFunction&&(i.texParameteri(T,i.TEXTURE_COMPARE_MODE,i.COMPARE_REF_TO_TEXTURE),i.texParameteri(T,i.TEXTURE_COMPARE_FUNC,se[b.compareFunction])),e.has("EXT_texture_filter_anisotropic")===!0){if(b.magFilter===ii||b.minFilter!==ls&&b.minFilter!==xr||b.type===jn&&e.has("OES_texture_float_linear")===!1)return;if(b.anisotropy>1||n.get(b).__currentAnisotropy){let H=e.get("EXT_texture_filter_anisotropic");i.texParameterf(T,H.TEXTURE_MAX_ANISOTROPY_EXT,Math.min(b.anisotropy,r.getMaxAnisotropy())),n.get(b).__currentAnisotropy=b.anisotropy}}}function ee(T,b){let H=!1;T.__webglInit===void 0&&(T.__webglInit=!0,b.addEventListener("dispose",R));let U=b.source,M=d.get(U);M===void 0&&(M={},d.set(U,M));let A=(function(F){let P=[];return P.push(F.wrapS),P.push(F.wrapT),P.push(F.wrapR||0),P.push(F.magFilter),P.push(F.minFilter),P.push(F.anisotropy),P.push(F.internalFormat),P.push(F.format),P.push(F.type),P.push(F.generateMipmaps),P.push(F.premultiplyAlpha),P.push(F.flipY),P.push(F.unpackAlignment),P.push(F.colorSpace),P.join()})(b);if(A!==T.__cacheKey){M[A]===void 0&&(M[A]={texture:i.createTexture(),usedTimes:0},s.memory.textures++,H=!0),M[A].usedTimes++;let F=M[T.__cacheKey];F!==void 0&&(M[T.__cacheKey].usedTimes--,F.usedTimes===0&&G(b)),T.__cacheKey=A,T.__webglTexture=M[A].texture}return H}function Q(T,b,H){return Math.floor(Math.floor(T/H)/b)}function me(T,b,H){let U=i.TEXTURE_2D;(b.isDataArrayTexture||b.isCompressedArrayTexture)&&(U=i.TEXTURE_2D_ARRAY),b.isData3DTexture&&(U=i.TEXTURE_3D);let M=ee(T,b),A=b.source;t.bindTexture(U,T.__webglTexture,i.TEXTURE0+H);let F=n.get(A);if(A.version!==F.__version||M===!0){t.activeTexture(i.TEXTURE0+H);let P=ht.getPrimaries(ht.workingColorSpace),te=b.colorSpace===Sr?null:ht.getPrimaries(b.colorSpace),j=b.colorSpace===Sr||P===te?i.NONE:i.BROWSER_DEFAULT_WEBGL;i.pixelStorei(i.UNPACK_FLIP_Y_WEBGL,b.flipY),i.pixelStorei(i.UNPACK_PREMULTIPLY_ALPHA_WEBGL,b.premultiplyAlpha),i.pixelStorei(i.UNPACK_ALIGNMENT,b.unpackAlignment),i.pixelStorei(i.UNPACK_COLORSPACE_CONVERSION_WEBGL,j);let q=g(b.image,!1,r.maxTextureSize);q=Oe(b,q);let he=a.convert(b.format,b.colorSpace),Se=a.convert(b.type),ue,Re=y(b.internalFormat,he,Se,b.colorSpace,b.isVideoTexture);X(U,b);let De=b.mipmaps,Te=b.isVideoTexture!==!0,Ue=F.__version===void 0||M===!0,We=A.dataReady,it=w(b,q);if(b.isDepthTexture)Re=S(b.format===hs,b.type),Ue&&(Te?t.texStorage2D(i.TEXTURE_2D,1,Re,q.width,q.height):t.texImage2D(i.TEXTURE_2D,0,Re,q.width,q.height,0,he,Se,null));else if(b.isDataTexture)if(De.length>0){Te&&Ue&&t.texStorage2D(i.TEXTURE_2D,it,Re,De[0].width,De[0].height);for(let Ee=0,ke=De.length;Ee<ke;Ee++)ue=De[Ee],Te?We&&t.texSubImage2D(i.TEXTURE_2D,Ee,0,0,ue.width,ue.height,he,Se,ue.data):t.texImage2D(i.TEXTURE_2D,Ee,Re,ue.width,ue.height,0,he,Se,ue.data);b.generateMipmaps=!1}else Te?(Ue&&t.texStorage2D(i.TEXTURE_2D,it,Re,q.width,q.height),We&&(function(Ee,ke,Xe,Tt){let Ce=Ee.updateRanges;if(Ce.length===0)t.texSubImage2D(i.TEXTURE_2D,0,0,0,ke.width,ke.height,Xe,Tt,ke.data);else{Ce.sort((N,ut)=>N.start-ut.start);let ot=0;for(let N=1;N<Ce.length;N++){let ut=Ce[ot],Ct=Ce[N],lt=ut.start+ut.count,Mt=Q(Ct.start,ke.width,4),cn=Q(ut.start,ke.width,4);Ct.start<=lt+1&&Mt===cn&&Q(Ct.start+Ct.count-1,ke.width,4)===Mt?ut.count=Math.max(ut.count,Ct.start+Ct.count-ut.start):(++ot,Ce[ot]=Ct)}Ce.length=ot+1;let Ke=i.getParameter(i.UNPACK_ROW_LENGTH),Ut=i.getParameter(i.UNPACK_SKIP_PIXELS),Et=i.getParameter(i.UNPACK_SKIP_ROWS);i.pixelStorei(i.UNPACK_ROW_LENGTH,ke.width);for(let N=0,ut=Ce.length;N<ut;N++){let Ct=Ce[N],lt=Math.floor(Ct.start/4),Mt=Math.ceil(Ct.count/4),cn=lt%ke.width,Ot=Math.floor(lt/ke.width),An=Mt;i.pixelStorei(i.UNPACK_SKIP_PIXELS,cn),i.pixelStorei(i.UNPACK_SKIP_ROWS,Ot),t.texSubImage2D(i.TEXTURE_2D,0,cn,Ot,An,1,Xe,Tt,ke.data)}Ee.clearUpdateRanges(),i.pixelStorei(i.UNPACK_ROW_LENGTH,Ke),i.pixelStorei(i.UNPACK_SKIP_PIXELS,Ut),i.pixelStorei(i.UNPACK_SKIP_ROWS,Et)}})(b,q,he,Se)):t.texImage2D(i.TEXTURE_2D,0,Re,q.width,q.height,0,he,Se,q.data);else if(b.isCompressedTexture)if(b.isCompressedArrayTexture){Te&&Ue&&t.texStorage3D(i.TEXTURE_2D_ARRAY,it,Re,De[0].width,De[0].height,q.depth);for(let Ee=0,ke=De.length;Ee<ke;Ee++)if(ue=De[Ee],b.format!==qn)if(he!==null)if(Te){if(We)if(b.layerUpdates.size>0){let Xe=$c(ue.width,ue.height,b.format,b.type);for(let Tt of b.layerUpdates){let Ce=ue.data.subarray(Tt*Xe/ue.data.BYTES_PER_ELEMENT,(Tt+1)*Xe/ue.data.BYTES_PER_ELEMENT);t.compressedTexSubImage3D(i.TEXTURE_2D_ARRAY,Ee,0,0,Tt,ue.width,ue.height,1,he,Ce)}b.clearLayerUpdates()}else t.compressedTexSubImage3D(i.TEXTURE_2D_ARRAY,Ee,0,0,0,ue.width,ue.height,q.depth,he,ue.data)}else t.compressedTexImage3D(i.TEXTURE_2D_ARRAY,Ee,Re,ue.width,ue.height,q.depth,0,ue.data,0,0);else console.warn("THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .uploadTexture()");else Te?We&&t.texSubImage3D(i.TEXTURE_2D_ARRAY,Ee,0,0,0,ue.width,ue.height,q.depth,he,Se,ue.data):t.texImage3D(i.TEXTURE_2D_ARRAY,Ee,Re,ue.width,ue.height,q.depth,0,he,Se,ue.data)}else{Te&&Ue&&t.texStorage2D(i.TEXTURE_2D,it,Re,De[0].width,De[0].height);for(let Ee=0,ke=De.length;Ee<ke;Ee++)ue=De[Ee],b.format!==qn?he!==null?Te?We&&t.compressedTexSubImage2D(i.TEXTURE_2D,Ee,0,0,ue.width,ue.height,he,ue.data):t.compressedTexImage2D(i.TEXTURE_2D,Ee,Re,ue.width,ue.height,0,ue.data):console.warn("THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .uploadTexture()"):Te?We&&t.texSubImage2D(i.TEXTURE_2D,Ee,0,0,ue.width,ue.height,he,Se,ue.data):t.texImage2D(i.TEXTURE_2D,Ee,Re,ue.width,ue.height,0,he,Se,ue.data)}else if(b.isDataArrayTexture)if(Te){if(Ue&&t.texStorage3D(i.TEXTURE_2D_ARRAY,it,Re,q.width,q.height,q.depth),We)if(b.layerUpdates.size>0){let Ee=$c(q.width,q.height,b.format,b.type);for(let ke of b.layerUpdates){let Xe=q.data.subarray(ke*Ee/q.data.BYTES_PER_ELEMENT,(ke+1)*Ee/q.data.BYTES_PER_ELEMENT);t.texSubImage3D(i.TEXTURE_2D_ARRAY,0,0,0,ke,q.width,q.height,1,he,Se,Xe)}b.clearLayerUpdates()}else t.texSubImage3D(i.TEXTURE_2D_ARRAY,0,0,0,0,q.width,q.height,q.depth,he,Se,q.data)}else t.texImage3D(i.TEXTURE_2D_ARRAY,0,Re,q.width,q.height,q.depth,0,he,Se,q.data);else if(b.isData3DTexture)Te?(Ue&&t.texStorage3D(i.TEXTURE_3D,it,Re,q.width,q.height,q.depth),We&&t.texSubImage3D(i.TEXTURE_3D,0,0,0,0,q.width,q.height,q.depth,he,Se,q.data)):t.texImage3D(i.TEXTURE_3D,0,Re,q.width,q.height,q.depth,0,he,Se,q.data);else if(b.isFramebufferTexture){if(Ue)if(Te)t.texStorage2D(i.TEXTURE_2D,it,Re,q.width,q.height);else{let Ee=q.width,ke=q.height;for(let Xe=0;Xe<it;Xe++)t.texImage2D(i.TEXTURE_2D,Xe,Re,Ee,ke,0,he,Se,null),Ee>>=1,ke>>=1}}else if(De.length>0){if(Te&&Ue){let Ee=Ge(De[0]);t.texStorage2D(i.TEXTURE_2D,it,Re,Ee.width,Ee.height)}for(let Ee=0,ke=De.length;Ee<ke;Ee++)ue=De[Ee],Te?We&&t.texSubImage2D(i.TEXTURE_2D,Ee,0,0,he,Se,ue):t.texImage2D(i.TEXTURE_2D,Ee,Re,he,Se,ue);b.generateMipmaps=!1}else if(Te){if(Ue){let Ee=Ge(q);t.texStorage2D(i.TEXTURE_2D,it,Re,Ee.width,Ee.height)}We&&t.texSubImage2D(i.TEXTURE_2D,0,0,0,he,Se,q)}else t.texImage2D(i.TEXTURE_2D,0,Re,he,Se,q);f(b)&&v(U),F.__version=A.version,b.onUpdate&&b.onUpdate(b)}T.__version=b.version}function ae(T,b,H,U,M,A){let F=a.convert(H.format,H.colorSpace),P=a.convert(H.type),te=y(H.internalFormat,F,P,H.colorSpace),j=n.get(b),q=n.get(H);if(q.__renderTarget=b,!j.__hasExternalTextures){let he=Math.max(1,b.width>>A),Se=Math.max(1,b.height>>A);M===i.TEXTURE_3D||M===i.TEXTURE_2D_ARRAY?t.texImage3D(M,A,te,he,Se,b.depth,0,F,P,null):t.texImage2D(M,A,te,he,Se,0,F,P,null)}t.bindFramebuffer(i.FRAMEBUFFER,T),ne(b)?o.framebufferTexture2DMultisampleEXT(i.FRAMEBUFFER,U,M,q.__webglTexture,0,re(b)):(M===i.TEXTURE_2D||M>=i.TEXTURE_CUBE_MAP_POSITIVE_X&&M<=i.TEXTURE_CUBE_MAP_NEGATIVE_Z)&&i.framebufferTexture2D(i.FRAMEBUFFER,U,M,q.__webglTexture,A),t.bindFramebuffer(i.FRAMEBUFFER,null)}function be(T,b,H){if(i.bindRenderbuffer(i.RENDERBUFFER,T),b.depthBuffer){let U=b.depthTexture,M=U&&U.isDepthTexture?U.type:null,A=S(b.stencilBuffer,M),F=b.stencilBuffer?i.DEPTH_STENCIL_ATTACHMENT:i.DEPTH_ATTACHMENT,P=re(b);ne(b)?o.renderbufferStorageMultisampleEXT(i.RENDERBUFFER,P,A,b.width,b.height):H?i.renderbufferStorageMultisample(i.RENDERBUFFER,P,A,b.width,b.height):i.renderbufferStorage(i.RENDERBUFFER,A,b.width,b.height),i.framebufferRenderbuffer(i.FRAMEBUFFER,F,i.RENDERBUFFER,T)}else{let U=b.textures;for(let M=0;M<U.length;M++){let A=U[M],F=a.convert(A.format,A.colorSpace),P=a.convert(A.type),te=y(A.internalFormat,F,P,A.colorSpace),j=re(b);H&&ne(b)===!1?i.renderbufferStorageMultisample(i.RENDERBUFFER,j,te,b.width,b.height):ne(b)?o.renderbufferStorageMultisampleEXT(i.RENDERBUFFER,j,te,b.width,b.height):i.renderbufferStorage(i.RENDERBUFFER,te,b.width,b.height)}}i.bindRenderbuffer(i.RENDERBUFFER,null)}function Be(T,b){if(b&&b.isWebGLCubeRenderTarget)throw new Error("Depth Texture with cube render targets is not supported");if(t.bindFramebuffer(i.FRAMEBUFFER,T),!b.depthTexture||!b.depthTexture.isDepthTexture)throw new Error("renderTarget.depthTexture must be an instance of THREE.DepthTexture");let H=n.get(b.depthTexture);H.__renderTarget=b,H.__webglTexture&&b.depthTexture.image.width===b.width&&b.depthTexture.image.height===b.height||(b.depthTexture.image.width=b.width,b.depthTexture.image.height=b.height,b.depthTexture.needsUpdate=!0),J(b.depthTexture,0);let U=H.__webglTexture,M=re(b);if(b.depthTexture.format===cs)ne(b)?o.framebufferTexture2DMultisampleEXT(i.FRAMEBUFFER,i.DEPTH_ATTACHMENT,i.TEXTURE_2D,U,0,M):i.framebufferTexture2D(i.FRAMEBUFFER,i.DEPTH_ATTACHMENT,i.TEXTURE_2D,U,0);else{if(b.depthTexture.format!==hs)throw new Error("Unknown depthTexture format");ne(b)?o.framebufferTexture2DMultisampleEXT(i.FRAMEBUFFER,i.DEPTH_STENCIL_ATTACHMENT,i.TEXTURE_2D,U,0,M):i.framebufferTexture2D(i.FRAMEBUFFER,i.DEPTH_STENCIL_ATTACHMENT,i.TEXTURE_2D,U,0)}}function Ie(T){let b=n.get(T),H=T.isWebGLCubeRenderTarget===!0;if(b.__boundDepthTexture!==T.depthTexture){let U=T.depthTexture;if(b.__depthDisposeCallback&&b.__depthDisposeCallback(),U){let M=()=>{delete b.__boundDepthTexture,delete b.__depthDisposeCallback,U.removeEventListener("dispose",M)};U.addEventListener("dispose",M),b.__depthDisposeCallback=M}b.__boundDepthTexture=U}if(T.depthTexture&&!b.__autoAllocateDepthBuffer){if(H)throw new Error("target.depthTexture not supported in Cube render targets");let U=T.texture.mipmaps;U&&U.length>0?Be(b.__webglFramebuffer[0],T):Be(b.__webglFramebuffer,T)}else if(H){b.__webglDepthbuffer=[];for(let U=0;U<6;U++)if(t.bindFramebuffer(i.FRAMEBUFFER,b.__webglFramebuffer[U]),b.__webglDepthbuffer[U]===void 0)b.__webglDepthbuffer[U]=i.createRenderbuffer(),be(b.__webglDepthbuffer[U],T,!1);else{let M=T.stencilBuffer?i.DEPTH_STENCIL_ATTACHMENT:i.DEPTH_ATTACHMENT,A=b.__webglDepthbuffer[U];i.bindRenderbuffer(i.RENDERBUFFER,A),i.framebufferRenderbuffer(i.FRAMEBUFFER,M,i.RENDERBUFFER,A)}}else{let U=T.texture.mipmaps;if(U&&U.length>0?t.bindFramebuffer(i.FRAMEBUFFER,b.__webglFramebuffer[0]):t.bindFramebuffer(i.FRAMEBUFFER,b.__webglFramebuffer),b.__webglDepthbuffer===void 0)b.__webglDepthbuffer=i.createRenderbuffer(),be(b.__webglDepthbuffer,T,!1);else{let M=T.stencilBuffer?i.DEPTH_STENCIL_ATTACHMENT:i.DEPTH_ATTACHMENT,A=b.__webglDepthbuffer;i.bindRenderbuffer(i.RENDERBUFFER,A),i.framebufferRenderbuffer(i.FRAMEBUFFER,M,i.RENDERBUFFER,A)}}t.bindFramebuffer(i.FRAMEBUFFER,null)}let Ne=[],le=[];function re(T){return Math.min(r.maxSamples,T.samples)}function ne(T){let b=n.get(T);return T.samples>0&&e.has("WEBGL_multisampled_render_to_texture")===!0&&b.__useRenderToTexture!==!1}function Oe(T,b){let H=T.colorSpace,U=T.format,M=T.type;return T.isCompressedTexture===!0||T.isVideoTexture===!0||H!==pr&&H!==Sr&&(ht.getTransfer(H)===dt?U===qn&&M===ci||console.warn("THREE.WebGLTextures: sRGB encoded textures have to use RGBAFormat and UnsignedByteType."):console.error("THREE.WebGLTextures: Unsupported texture color space:",H)),b}function Ge(T){return typeof HTMLImageElement!="undefined"&&T instanceof HTMLImageElement?(l.width=T.naturalWidth||T.width,l.height=T.naturalHeight||T.height):typeof VideoFrame!="undefined"&&T instanceof VideoFrame?(l.width=T.displayWidth,l.height=T.displayHeight):(l.width=T.width,l.height=T.height),l}this.allocateTextureUnit=function(){let T=D;return T>=r.maxTextures&&console.warn("THREE.WebGLTextures: Trying to use "+T+" texture units while this GPU supports only "+r.maxTextures),D+=1,T},this.resetTextureUnits=function(){D=0},this.setTexture2D=J,this.setTexture2DArray=function(T,b){let H=n.get(T);T.isRenderTargetTexture===!1&&T.version>0&&H.__version!==T.version?me(H,T,b):t.bindTexture(i.TEXTURE_2D_ARRAY,H.__webglTexture,i.TEXTURE0+b)},this.setTexture3D=function(T,b){let H=n.get(T);T.isRenderTargetTexture===!1&&T.version>0&&H.__version!==T.version?me(H,T,b):t.bindTexture(i.TEXTURE_3D,H.__webglTexture,i.TEXTURE0+b)},this.setTextureCube=function(T,b){let H=n.get(T);T.version>0&&H.__version!==T.version?(function(U,M,A){if(M.image.length!==6)return;let F=ee(U,M),P=M.source;t.bindTexture(i.TEXTURE_CUBE_MAP,U.__webglTexture,i.TEXTURE0+A);let te=n.get(P);if(P.version!==te.__version||F===!0){t.activeTexture(i.TEXTURE0+A);let j=ht.getPrimaries(ht.workingColorSpace),q=M.colorSpace===Sr?null:ht.getPrimaries(M.colorSpace),he=M.colorSpace===Sr||j===q?i.NONE:i.BROWSER_DEFAULT_WEBGL;i.pixelStorei(i.UNPACK_FLIP_Y_WEBGL,M.flipY),i.pixelStorei(i.UNPACK_PREMULTIPLY_ALPHA_WEBGL,M.premultiplyAlpha),i.pixelStorei(i.UNPACK_ALIGNMENT,M.unpackAlignment),i.pixelStorei(i.UNPACK_COLORSPACE_CONVERSION_WEBGL,he);let Se=M.isCompressedTexture||M.image[0].isCompressedTexture,ue=M.image[0]&&M.image[0].isDataTexture,Re=[];for(let Ce=0;Ce<6;Ce++)Re[Ce]=Se||ue?ue?M.image[Ce].image:M.image[Ce]:g(M.image[Ce],!0,r.maxCubemapSize),Re[Ce]=Oe(M,Re[Ce]);let De=Re[0],Te=a.convert(M.format,M.colorSpace),Ue=a.convert(M.type),We=y(M.internalFormat,Te,Ue,M.colorSpace),it=M.isVideoTexture!==!0,Ee=te.__version===void 0||F===!0,ke=P.dataReady,Xe,Tt=w(M,De);if(X(i.TEXTURE_CUBE_MAP,M),Se){it&&Ee&&t.texStorage2D(i.TEXTURE_CUBE_MAP,Tt,We,De.width,De.height);for(let Ce=0;Ce<6;Ce++){Xe=Re[Ce].mipmaps;for(let ot=0;ot<Xe.length;ot++){let Ke=Xe[ot];M.format!==qn?Te!==null?it?ke&&t.compressedTexSubImage2D(i.TEXTURE_CUBE_MAP_POSITIVE_X+Ce,ot,0,0,Ke.width,Ke.height,Te,Ke.data):t.compressedTexImage2D(i.TEXTURE_CUBE_MAP_POSITIVE_X+Ce,ot,We,Ke.width,Ke.height,0,Ke.data):console.warn("THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .setTextureCube()"):it?ke&&t.texSubImage2D(i.TEXTURE_CUBE_MAP_POSITIVE_X+Ce,ot,0,0,Ke.width,Ke.height,Te,Ue,Ke.data):t.texImage2D(i.TEXTURE_CUBE_MAP_POSITIVE_X+Ce,ot,We,Ke.width,Ke.height,0,Te,Ue,Ke.data)}}}else{if(Xe=M.mipmaps,it&&Ee){Xe.length>0&&Tt++;let Ce=Ge(Re[0]);t.texStorage2D(i.TEXTURE_CUBE_MAP,Tt,We,Ce.width,Ce.height)}for(let Ce=0;Ce<6;Ce++)if(ue){it?ke&&t.texSubImage2D(i.TEXTURE_CUBE_MAP_POSITIVE_X+Ce,0,0,0,Re[Ce].width,Re[Ce].height,Te,Ue,Re[Ce].data):t.texImage2D(i.TEXTURE_CUBE_MAP_POSITIVE_X+Ce,0,We,Re[Ce].width,Re[Ce].height,0,Te,Ue,Re[Ce].data);for(let ot=0;ot<Xe.length;ot++){let Ke=Xe[ot].image[Ce].image;it?ke&&t.texSubImage2D(i.TEXTURE_CUBE_MAP_POSITIVE_X+Ce,ot+1,0,0,Ke.width,Ke.height,Te,Ue,Ke.data):t.texImage2D(i.TEXTURE_CUBE_MAP_POSITIVE_X+Ce,ot+1,We,Ke.width,Ke.height,0,Te,Ue,Ke.data)}}else{it?ke&&t.texSubImage2D(i.TEXTURE_CUBE_MAP_POSITIVE_X+Ce,0,0,0,Te,Ue,Re[Ce]):t.texImage2D(i.TEXTURE_CUBE_MAP_POSITIVE_X+Ce,0,We,Te,Ue,Re[Ce]);for(let ot=0;ot<Xe.length;ot++){let Ke=Xe[ot];it?ke&&t.texSubImage2D(i.TEXTURE_CUBE_MAP_POSITIVE_X+Ce,ot+1,0,0,Te,Ue,Ke.image[Ce]):t.texImage2D(i.TEXTURE_CUBE_MAP_POSITIVE_X+Ce,ot+1,We,Te,Ue,Ke.image[Ce])}}}f(M)&&v(i.TEXTURE_CUBE_MAP),te.__version=P.version,M.onUpdate&&M.onUpdate(M)}U.__version=M.version})(H,T,b):t.bindTexture(i.TEXTURE_CUBE_MAP,H.__webglTexture,i.TEXTURE0+b)},this.rebindTextures=function(T,b,H){let U=n.get(T);b!==void 0&&ae(U.__webglFramebuffer,T,T.texture,i.COLOR_ATTACHMENT0,i.TEXTURE_2D,0),H!==void 0&&Ie(T)},this.setupRenderTarget=function(T){let b=T.texture,H=n.get(T),U=n.get(b);T.addEventListener("dispose",B);let M=T.textures,A=T.isWebGLCubeRenderTarget===!0,F=M.length>1;if(F||(U.__webglTexture===void 0&&(U.__webglTexture=i.createTexture()),U.__version=b.version,s.memory.textures++),A){H.__webglFramebuffer=[];for(let P=0;P<6;P++)if(b.mipmaps&&b.mipmaps.length>0){H.__webglFramebuffer[P]=[];for(let te=0;te<b.mipmaps.length;te++)H.__webglFramebuffer[P][te]=i.createFramebuffer()}else H.__webglFramebuffer[P]=i.createFramebuffer()}else{if(b.mipmaps&&b.mipmaps.length>0){H.__webglFramebuffer=[];for(let P=0;P<b.mipmaps.length;P++)H.__webglFramebuffer[P]=i.createFramebuffer()}else H.__webglFramebuffer=i.createFramebuffer();if(F)for(let P=0,te=M.length;P<te;P++){let j=n.get(M[P]);j.__webglTexture===void 0&&(j.__webglTexture=i.createTexture(),s.memory.textures++)}if(T.samples>0&&ne(T)===!1){H.__webglMultisampledFramebuffer=i.createFramebuffer(),H.__webglColorRenderbuffer=[],t.bindFramebuffer(i.FRAMEBUFFER,H.__webglMultisampledFramebuffer);for(let P=0;P<M.length;P++){let te=M[P];H.__webglColorRenderbuffer[P]=i.createRenderbuffer(),i.bindRenderbuffer(i.RENDERBUFFER,H.__webglColorRenderbuffer[P]);let j=a.convert(te.format,te.colorSpace),q=a.convert(te.type),he=y(te.internalFormat,j,q,te.colorSpace,T.isXRRenderTarget===!0),Se=re(T);i.renderbufferStorageMultisample(i.RENDERBUFFER,Se,he,T.width,T.height),i.framebufferRenderbuffer(i.FRAMEBUFFER,i.COLOR_ATTACHMENT0+P,i.RENDERBUFFER,H.__webglColorRenderbuffer[P])}i.bindRenderbuffer(i.RENDERBUFFER,null),T.depthBuffer&&(H.__webglDepthRenderbuffer=i.createRenderbuffer(),be(H.__webglDepthRenderbuffer,T,!0)),t.bindFramebuffer(i.FRAMEBUFFER,null)}}if(A){t.bindTexture(i.TEXTURE_CUBE_MAP,U.__webglTexture),X(i.TEXTURE_CUBE_MAP,b);for(let P=0;P<6;P++)if(b.mipmaps&&b.mipmaps.length>0)for(let te=0;te<b.mipmaps.length;te++)ae(H.__webglFramebuffer[P][te],T,b,i.COLOR_ATTACHMENT0,i.TEXTURE_CUBE_MAP_POSITIVE_X+P,te);else ae(H.__webglFramebuffer[P],T,b,i.COLOR_ATTACHMENT0,i.TEXTURE_CUBE_MAP_POSITIVE_X+P,0);f(b)&&v(i.TEXTURE_CUBE_MAP),t.unbindTexture()}else if(F){for(let P=0,te=M.length;P<te;P++){let j=M[P],q=n.get(j),he=i.TEXTURE_2D;(T.isWebGL3DRenderTarget||T.isWebGLArrayRenderTarget)&&(he=T.isWebGL3DRenderTarget?i.TEXTURE_3D:i.TEXTURE_2D_ARRAY),t.bindTexture(he,q.__webglTexture),X(he,j),ae(H.__webglFramebuffer,T,j,i.COLOR_ATTACHMENT0+P,he,0),f(j)&&v(he)}t.unbindTexture()}else{let P=i.TEXTURE_2D;if((T.isWebGL3DRenderTarget||T.isWebGLArrayRenderTarget)&&(P=T.isWebGL3DRenderTarget?i.TEXTURE_3D:i.TEXTURE_2D_ARRAY),t.bindTexture(P,U.__webglTexture),X(P,b),b.mipmaps&&b.mipmaps.length>0)for(let te=0;te<b.mipmaps.length;te++)ae(H.__webglFramebuffer[te],T,b,i.COLOR_ATTACHMENT0,P,te);else ae(H.__webglFramebuffer,T,b,i.COLOR_ATTACHMENT0,P,0);f(b)&&v(P),t.unbindTexture()}T.depthBuffer&&Ie(T)},this.updateRenderTargetMipmap=function(T){let b=T.textures;for(let H=0,U=b.length;H<U;H++){let M=b[H];if(f(M)){let A=_(T),F=n.get(M).__webglTexture;t.bindTexture(A,F),v(A),t.unbindTexture()}}},this.updateMultisampleRenderTarget=function(T){if(T.samples>0){if(ne(T)===!1){let b=T.textures,H=T.width,U=T.height,M=i.COLOR_BUFFER_BIT,A=T.stencilBuffer?i.DEPTH_STENCIL_ATTACHMENT:i.DEPTH_ATTACHMENT,F=n.get(T),P=b.length>1;if(P)for(let j=0;j<b.length;j++)t.bindFramebuffer(i.FRAMEBUFFER,F.__webglMultisampledFramebuffer),i.framebufferRenderbuffer(i.FRAMEBUFFER,i.COLOR_ATTACHMENT0+j,i.RENDERBUFFER,null),t.bindFramebuffer(i.FRAMEBUFFER,F.__webglFramebuffer),i.framebufferTexture2D(i.DRAW_FRAMEBUFFER,i.COLOR_ATTACHMENT0+j,i.TEXTURE_2D,null,0);t.bindFramebuffer(i.READ_FRAMEBUFFER,F.__webglMultisampledFramebuffer);let te=T.texture.mipmaps;te&&te.length>0?t.bindFramebuffer(i.DRAW_FRAMEBUFFER,F.__webglFramebuffer[0]):t.bindFramebuffer(i.DRAW_FRAMEBUFFER,F.__webglFramebuffer);for(let j=0;j<b.length;j++){if(T.resolveDepthBuffer&&(T.depthBuffer&&(M|=i.DEPTH_BUFFER_BIT),T.stencilBuffer&&T.resolveStencilBuffer&&(M|=i.STENCIL_BUFFER_BIT)),P){i.framebufferRenderbuffer(i.READ_FRAMEBUFFER,i.COLOR_ATTACHMENT0,i.RENDERBUFFER,F.__webglColorRenderbuffer[j]);let q=n.get(b[j]).__webglTexture;i.framebufferTexture2D(i.DRAW_FRAMEBUFFER,i.COLOR_ATTACHMENT0,i.TEXTURE_2D,q,0)}i.blitFramebuffer(0,0,H,U,0,0,H,U,M,i.NEAREST),c===!0&&(Ne.length=0,le.length=0,Ne.push(i.COLOR_ATTACHMENT0+j),T.depthBuffer&&T.resolveDepthBuffer===!1&&(Ne.push(A),le.push(A),i.invalidateFramebuffer(i.DRAW_FRAMEBUFFER,le)),i.invalidateFramebuffer(i.READ_FRAMEBUFFER,Ne))}if(t.bindFramebuffer(i.READ_FRAMEBUFFER,null),t.bindFramebuffer(i.DRAW_FRAMEBUFFER,null),P)for(let j=0;j<b.length;j++){t.bindFramebuffer(i.FRAMEBUFFER,F.__webglMultisampledFramebuffer),i.framebufferRenderbuffer(i.FRAMEBUFFER,i.COLOR_ATTACHMENT0+j,i.RENDERBUFFER,F.__webglColorRenderbuffer[j]);let q=n.get(b[j]).__webglTexture;t.bindFramebuffer(i.FRAMEBUFFER,F.__webglFramebuffer),i.framebufferTexture2D(i.DRAW_FRAMEBUFFER,i.COLOR_ATTACHMENT0+j,i.TEXTURE_2D,q,0)}t.bindFramebuffer(i.DRAW_FRAMEBUFFER,F.__webglMultisampledFramebuffer)}else if(T.depthBuffer&&T.resolveDepthBuffer===!1&&c){let b=T.stencilBuffer?i.DEPTH_STENCIL_ATTACHMENT:i.DEPTH_ATTACHMENT;i.invalidateFramebuffer(i.DRAW_FRAMEBUFFER,[b])}}},this.setupDepthRenderbuffer=Ie,this.setupFrameBufferTexture=ae,this.useMultisampledRTT=ne}function _m(i,e){return{convert:function(t,n=Sr){let r,a=ht.getTransfer(n);if(t===ci)return i.UNSIGNED_BYTE;if(t===Yo)return i.UNSIGNED_SHORT_4_4_4_4;if(t===Zo)return i.UNSIGNED_SHORT_5_5_5_1;if(t===pc)return i.UNSIGNED_INT_5_9_9_9_REV;if(t===fc)return i.UNSIGNED_INT_10F_11F_11F_REV;if(t===uc)return i.BYTE;if(t===dc)return i.SHORT;if(t===ca)return i.UNSIGNED_SHORT;if(t===qo)return i.INT;if(t===Mr)return i.UNSIGNED_INT;if(t===jn)return i.FLOAT;if(t===ha)return i.HALF_FLOAT;if(t===Wu)return i.ALPHA;if(t===Xu)return i.RGB;if(t===qn)return i.RGBA;if(t===cs)return i.DEPTH_COMPONENT;if(t===hs)return i.DEPTH_STENCIL;if(t===Jo)return i.RED;if(t===Ko)return i.RED_INTEGER;if(t===ju)return i.RG;if(t===mc)return i.RG_INTEGER;if(t===gc)return i.RGBA_INTEGER;if(t===$o||t===Qo||t===el||t===tl)if(a===dt){if(r=e.get("WEBGL_compressed_texture_s3tc_srgb"),r===null)return null;if(t===$o)return r.COMPRESSED_SRGB_S3TC_DXT1_EXT;if(t===Qo)return r.COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT;if(t===el)return r.COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT;if(t===tl)return r.COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT}else{if(r=e.get("WEBGL_compressed_texture_s3tc"),r===null)return null;if(t===$o)return r.COMPRESSED_RGB_S3TC_DXT1_EXT;if(t===Qo)return r.COMPRESSED_RGBA_S3TC_DXT1_EXT;if(t===el)return r.COMPRESSED_RGBA_S3TC_DXT3_EXT;if(t===tl)return r.COMPRESSED_RGBA_S3TC_DXT5_EXT}if(t===vc||t===_c||t===yc||t===xc){if(r=e.get("WEBGL_compressed_texture_pvrtc"),r===null)return null;if(t===vc)return r.COMPRESSED_RGB_PVRTC_4BPPV1_IMG;if(t===_c)return r.COMPRESSED_RGB_PVRTC_2BPPV1_IMG;if(t===yc)return r.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG;if(t===xc)return r.COMPRESSED_RGBA_PVRTC_2BPPV1_IMG}if(t===Mc||t===Sc||t===bc){if(r=e.get("WEBGL_compressed_texture_etc"),r===null)return null;if(t===Mc||t===Sc)return a===dt?r.COMPRESSED_SRGB8_ETC2:r.COMPRESSED_RGB8_ETC2;if(t===bc)return a===dt?r.COMPRESSED_SRGB8_ALPHA8_ETC2_EAC:r.COMPRESSED_RGBA8_ETC2_EAC}if(t===Tc||t===Ec||t===wc||t===Ac||t===Rc||t===Cc||t===Pc||t===Ic||t===Lc||t===Dc||t===Uc||t===Nc||t===Fc||t===Oc){if(r=e.get("WEBGL_compressed_texture_astc"),r===null)return null;if(t===Tc)return a===dt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR:r.COMPRESSED_RGBA_ASTC_4x4_KHR;if(t===Ec)return a===dt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR:r.COMPRESSED_RGBA_ASTC_5x4_KHR;if(t===wc)return a===dt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR:r.COMPRESSED_RGBA_ASTC_5x5_KHR;if(t===Ac)return a===dt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR:r.COMPRESSED_RGBA_ASTC_6x5_KHR;if(t===Rc)return a===dt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR:r.COMPRESSED_RGBA_ASTC_6x6_KHR;if(t===Cc)return a===dt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR:r.COMPRESSED_RGBA_ASTC_8x5_KHR;if(t===Pc)return a===dt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR:r.COMPRESSED_RGBA_ASTC_8x6_KHR;if(t===Ic)return a===dt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR:r.COMPRESSED_RGBA_ASTC_8x8_KHR;if(t===Lc)return a===dt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR:r.COMPRESSED_RGBA_ASTC_10x5_KHR;if(t===Dc)return a===dt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR:r.COMPRESSED_RGBA_ASTC_10x6_KHR;if(t===Uc)return a===dt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR:r.COMPRESSED_RGBA_ASTC_10x8_KHR;if(t===Nc)return a===dt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR:r.COMPRESSED_RGBA_ASTC_10x10_KHR;if(t===Fc)return a===dt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR:r.COMPRESSED_RGBA_ASTC_12x10_KHR;if(t===Oc)return a===dt?r.COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR:r.COMPRESSED_RGBA_ASTC_12x12_KHR}if(t===Bc||t===kc||t===zc){if(r=e.get("EXT_texture_compression_bptc"),r===null)return null;if(t===Bc)return a===dt?r.COMPRESSED_SRGB_ALPHA_BPTC_UNORM_EXT:r.COMPRESSED_RGBA_BPTC_UNORM_EXT;if(t===kc)return r.COMPRESSED_RGB_BPTC_SIGNED_FLOAT_EXT;if(t===zc)return r.COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT_EXT}if(t===Hc||t===Gc||t===Vc||t===Wc){if(r=e.get("EXT_texture_compression_rgtc"),r===null)return null;if(t===Hc)return r.COMPRESSED_RED_RGTC1_EXT;if(t===Gc)return r.COMPRESSED_SIGNED_RED_RGTC1_EXT;if(t===Vc)return r.COMPRESSED_RED_GREEN_RGTC2_EXT;if(t===Wc)return r.COMPRESSED_SIGNED_RED_GREEN_RGTC2_EXT}return t===ua?i.UNSIGNED_INT_24_8:i[t]!==void 0?i[t]:null}}}var uh=class{constructor(){this.texture=null,this.mesh=null,this.depthNear=0,this.depthFar=0}init(e,t){if(this.texture===null){let n=new ja(e.texture);e.depthNear===t.depthNear&&e.depthFar===t.depthFar||(this.depthNear=e.depthNear,this.depthFar=e.depthFar),this.texture=n}}getMesh(e){if(this.texture!==null&&this.mesh===null){let t=e.cameras[0].viewport,n=new Dt({vertexShader:`
void main() {

	gl_Position = vec4( position, 1.0 );

}`,fragmentShader:`
uniform sampler2DArray depthColor;
uniform float depthWidth;
uniform float depthHeight;

void main() {

	vec2 coord = vec2( gl_FragCoord.x / depthWidth, gl_FragCoord.y / depthHeight );

	if ( coord.x >= 1.0 ) {

		gl_FragDepth = texture( depthColor, vec3( coord.x - 1.0, coord.y, 1 ) ).r;

	} else {

		gl_FragDepth = texture( depthColor, vec3( coord.x, coord.y, 0 ) ).r;

	}

}`,uniforms:{depthColor:{value:this.texture},depthWidth:{value:t.z},depthHeight:{value:t.w}}});this.mesh=new Le(new on(20,20),n)}return this.mesh}reset(){this.texture=null,this.mesh=null}getDepthTexture(){return this.texture}},dh=class extends wi{constructor(e,t){super();let n=this,r=null,a=1,s=null,o="local-floor",c=1,l=null,h=null,u=null,d=null,p=null,m=null,g=typeof XRWebGLBinding!="undefined",f=new uh,v={},_=t.getContextAttributes(),y=null,S=null,w=[],R=[],B=new pe,G=null,D=new rn;D.viewport=new xt;let J=new rn;J.viewport=new xt;let K=[D,J],V=new No,se=null,X=null;function ee(le){let re=R.indexOf(le.inputSource);if(re===-1)return;let ne=w[re];ne!==void 0&&(ne.update(le.inputSource,le.frame,l||s),ne.dispatchEvent({type:le.type,data:le.inputSource}))}function Q(){r.removeEventListener("select",ee),r.removeEventListener("selectstart",ee),r.removeEventListener("selectend",ee),r.removeEventListener("squeeze",ee),r.removeEventListener("squeezestart",ee),r.removeEventListener("squeezeend",ee),r.removeEventListener("end",Q),r.removeEventListener("inputsourceschange",me);for(let le=0;le<w.length;le++){let re=R[le];re!==null&&(R[le]=null,w[le].disconnect(re))}se=null,X=null,f.reset();for(let le in v)delete v[le];e.setRenderTarget(y),p=null,d=null,u=null,r=null,S=null,Ne.stop(),n.isPresenting=!1,e.setPixelRatio(G),e.setSize(B.width,B.height,!1),n.dispatchEvent({type:"sessionend"})}function me(le){for(let re=0;re<le.removed.length;re++){let ne=le.removed[re],Oe=R.indexOf(ne);Oe>=0&&(R[Oe]=null,w[Oe].disconnect(ne))}for(let re=0;re<le.added.length;re++){let ne=le.added[re],Oe=R.indexOf(ne);if(Oe===-1){for(let T=0;T<w.length;T++){if(T>=R.length){R.push(ne),Oe=T;break}if(R[T]===null){R[T]=ne,Oe=T;break}}if(Oe===-1)break}let Ge=w[Oe];Ge&&Ge.connect(ne)}}this.cameraAutoUpdate=!0,this.enabled=!1,this.isPresenting=!1,this.getController=function(le){let re=w[le];return re===void 0&&(re=new ia,w[le]=re),re.getTargetRaySpace()},this.getControllerGrip=function(le){let re=w[le];return re===void 0&&(re=new ia,w[le]=re),re.getGripSpace()},this.getHand=function(le){let re=w[le];return re===void 0&&(re=new ia,w[le]=re),re.getHandSpace()},this.setFramebufferScaleFactor=function(le){a=le,n.isPresenting===!0&&console.warn("THREE.WebXRManager: Cannot change framebuffer scale while presenting.")},this.setReferenceSpaceType=function(le){o=le,n.isPresenting===!0&&console.warn("THREE.WebXRManager: Cannot change reference space type while presenting.")},this.getReferenceSpace=function(){return l||s},this.setReferenceSpace=function(le){l=le},this.getBaseLayer=function(){return d!==null?d:p},this.getBinding=function(){return u===null&&g&&(u=new XRWebGLBinding(r,t)),u},this.getFrame=function(){return m},this.getSession=function(){return r},this.setSession=async function(le){if(r=le,r!==null){if(y=e.getRenderTarget(),r.addEventListener("select",ee),r.addEventListener("selectstart",ee),r.addEventListener("selectend",ee),r.addEventListener("squeeze",ee),r.addEventListener("squeezestart",ee),r.addEventListener("squeezeend",ee),r.addEventListener("end",Q),r.addEventListener("inputsourceschange",me),_.xrCompatible!==!0&&await t.makeXRCompatible(),G=e.getPixelRatio(),e.getSize(B),g&&"createProjectionLayer"in XRWebGLBinding.prototype){let re=null,ne=null,Oe=null;_.depth&&(Oe=_.stencil?t.DEPTH24_STENCIL8:t.DEPTH_COMPONENT24,re=_.stencil?hs:cs,ne=_.stencil?ua:Mr);let Ge={colorFormat:t.RGBA8,depthFormat:Oe,scaleFactor:a};u=this.getBinding(),d=u.createProjectionLayer(Ge),r.updateRenderState({layers:[d]}),e.setPixelRatio(1),e.setSize(d.textureWidth,d.textureHeight,!1),S=new yn(d.textureWidth,d.textureHeight,{format:qn,type:ci,depthTexture:new Xa(d.textureWidth,d.textureHeight,ne,void 0,void 0,void 0,void 0,void 0,void 0,re),stencilBuffer:_.stencil,colorSpace:e.outputColorSpace,samples:_.antialias?4:0,resolveDepthBuffer:d.ignoreDepthValues===!1,resolveStencilBuffer:d.ignoreDepthValues===!1})}else{let re={antialias:_.antialias,alpha:!0,depth:_.depth,stencil:_.stencil,framebufferScaleFactor:a};p=new XRWebGLLayer(r,t,re),r.updateRenderState({baseLayer:p}),e.setPixelRatio(1),e.setSize(p.framebufferWidth,p.framebufferHeight,!1),S=new yn(p.framebufferWidth,p.framebufferHeight,{format:qn,type:ci,colorSpace:e.outputColorSpace,stencilBuffer:_.stencil,resolveDepthBuffer:p.ignoreDepthValues===!1,resolveStencilBuffer:p.ignoreDepthValues===!1})}S.isXRRenderTarget=!0,this.setFoveation(c),l=null,s=await r.requestReferenceSpace(o),Ne.setContext(r),Ne.start(),n.isPresenting=!0,n.dispatchEvent({type:"sessionstart"})}},this.getEnvironmentBlendMode=function(){if(r!==null)return r.environmentBlendMode},this.getDepthTexture=function(){return f.getDepthTexture()};let ae=new E,be=new E;function Be(le,re){re===null?le.matrixWorld.copy(le.matrix):le.matrixWorld.multiplyMatrices(re.matrixWorld,le.matrix),le.matrixWorldInverse.copy(le.matrixWorld).invert()}this.updateCamera=function(le){if(r===null)return;let re=le.near,ne=le.far;f.texture!==null&&(f.depthNear>0&&(re=f.depthNear),f.depthFar>0&&(ne=f.depthFar)),V.near=J.near=D.near=re,V.far=J.far=D.far=ne,se===V.near&&X===V.far||(r.updateRenderState({depthNear:V.near,depthFar:V.far}),se=V.near,X=V.far),V.layers.mask=6|le.layers.mask,D.layers.mask=3&V.layers.mask,J.layers.mask=5&V.layers.mask;let Oe=le.parent,Ge=V.cameras;Be(V,Oe);for(let T=0;T<Ge.length;T++)Be(Ge[T],Oe);Ge.length===2?(function(T,b,H){ae.setFromMatrixPosition(b.matrixWorld),be.setFromMatrixPosition(H.matrixWorld);let U=ae.distanceTo(be),M=b.projectionMatrix.elements,A=H.projectionMatrix.elements,F=M[14]/(M[10]-1),P=M[14]/(M[10]+1),te=(M[9]+1)/M[5],j=(M[9]-1)/M[5],q=(M[8]-1)/M[0],he=(A[8]+1)/A[0],Se=F*q,ue=F*he,Re=U/(-q+he),De=Re*-q;if(b.matrixWorld.decompose(T.position,T.quaternion,T.scale),T.translateX(De),T.translateZ(Re),T.matrixWorld.compose(T.position,T.quaternion,T.scale),T.matrixWorldInverse.copy(T.matrixWorld).invert(),M[10]===-1)T.projectionMatrix.copy(b.projectionMatrix),T.projectionMatrixInverse.copy(b.projectionMatrixInverse);else{let Te=F+Re,Ue=P+Re,We=Se-De,it=ue+(U-De),Ee=te*P/Ue*Te,ke=j*P/Ue*Te;T.projectionMatrix.makePerspective(We,it,Ee,ke,Te,Ue),T.projectionMatrixInverse.copy(T.projectionMatrix).invert()}})(V,D,J):V.projectionMatrix.copy(D.projectionMatrix),(function(T,b,H){H===null?T.matrix.copy(b.matrixWorld):(T.matrix.copy(H.matrixWorld),T.matrix.invert(),T.matrix.multiply(b.matrixWorld)),T.matrix.decompose(T.position,T.quaternion,T.scale),T.updateMatrixWorld(!0),T.projectionMatrix.copy(b.projectionMatrix),T.projectionMatrixInverse.copy(b.projectionMatrixInverse),T.isPerspectiveCamera&&(T.fov=2*Qr*Math.atan(1/T.projectionMatrix.elements[5]),T.zoom=1)})(le,V,Oe)},this.getCamera=function(){return V},this.getFoveation=function(){if(d!==null||p!==null)return c},this.setFoveation=function(le){c=le,d!==null&&(d.fixedFoveation=le),p!==null&&p.fixedFoveation!==void 0&&(p.fixedFoveation=le)},this.hasDepthSensing=function(){return f.texture!==null},this.getDepthSensingMesh=function(){return f.getMesh(V)},this.getCameraTexture=function(le){return v[le]};let Ie=null,Ne=new Ud;Ne.setAnimationLoop(function(le,re){if(h=re.getViewerPose(l||s),m=re,h!==null){let ne=h.views;p!==null&&(e.setRenderTargetFramebuffer(S,p.framebuffer),e.setRenderTarget(S));let Oe=!1;ne.length!==V.cameras.length&&(V.cameras.length=0,Oe=!0);for(let T=0;T<ne.length;T++){let b=ne[T],H=null;if(p!==null)H=p.getViewport(b);else{let M=u.getViewSubImage(d,b);H=M.viewport,T===0&&(e.setRenderTargetTextures(S,M.colorTexture,M.depthStencilTexture),e.setRenderTarget(S))}let U=K[T];U===void 0&&(U=new rn,U.layers.enable(T),U.viewport=new xt,K[T]=U),U.matrix.fromArray(b.transform.matrix),U.matrix.decompose(U.position,U.quaternion,U.scale),U.projectionMatrix.fromArray(b.projectionMatrix),U.projectionMatrixInverse.copy(U.projectionMatrix).invert(),U.viewport.set(H.x,H.y,H.width,H.height),T===0&&(V.matrix.copy(U.matrix),V.matrix.decompose(V.position,V.quaternion,V.scale)),Oe===!0&&V.cameras.push(U)}let Ge=r.enabledFeatures;if(Ge&&Ge.includes("depth-sensing")&&r.depthUsage=="gpu-optimized"&&g){u=n.getBinding();let T=u.getDepthInformation(ne[0]);T&&T.isValid&&T.texture&&f.init(T,r.renderState)}if(Ge&&Ge.includes("camera-access")&&g){e.state.unbindTexture(),u=n.getBinding();for(let T=0;T<ne.length;T++){let b=ne[T].camera;if(b){let H=v[b];H||(H=new ja,v[b]=H);let U=u.getCameraImage(b);H.sourceTexture=U}}}}for(let ne=0;ne<w.length;ne++){let Oe=R[ne],Ge=w[ne];Oe!==null&&Ge!==void 0&&Ge.update(Oe,re,l||s)}Ie&&Ie(le,re),re.detectedPlanes&&n.dispatchEvent({type:"planesdetected",data:re}),m=null}),this.setAnimationLoop=function(le){Ie=le},this.dispose=function(){}}},wr=new an,ym=new qe;function xm(i,e){function t(r,a){r.matrixAutoUpdate===!0&&r.updateMatrix(),a.value.copy(r.matrix)}function n(r,a){r.opacity.value=a.opacity,a.color&&r.diffuse.value.copy(a.color),a.emissive&&r.emissive.value.copy(a.emissive).multiplyScalar(a.emissiveIntensity),a.map&&(r.map.value=a.map,t(a.map,r.mapTransform)),a.alphaMap&&(r.alphaMap.value=a.alphaMap,t(a.alphaMap,r.alphaMapTransform)),a.bumpMap&&(r.bumpMap.value=a.bumpMap,t(a.bumpMap,r.bumpMapTransform),r.bumpScale.value=a.bumpScale,a.side===Xt&&(r.bumpScale.value*=-1)),a.normalMap&&(r.normalMap.value=a.normalMap,t(a.normalMap,r.normalMapTransform),r.normalScale.value.copy(a.normalScale),a.side===Xt&&r.normalScale.value.negate()),a.displacementMap&&(r.displacementMap.value=a.displacementMap,t(a.displacementMap,r.displacementMapTransform),r.displacementScale.value=a.displacementScale,r.displacementBias.value=a.displacementBias),a.emissiveMap&&(r.emissiveMap.value=a.emissiveMap,t(a.emissiveMap,r.emissiveMapTransform)),a.specularMap&&(r.specularMap.value=a.specularMap,t(a.specularMap,r.specularMapTransform)),a.alphaTest>0&&(r.alphaTest.value=a.alphaTest);let s=e.get(a),o=s.envMap,c=s.envMapRotation;o&&(r.envMap.value=o,wr.copy(c),wr.x*=-1,wr.y*=-1,wr.z*=-1,o.isCubeTexture&&o.isRenderTargetTexture===!1&&(wr.y*=-1,wr.z*=-1),r.envMapRotation.value.setFromMatrix4(ym.makeRotationFromEuler(wr)),r.flipEnvMap.value=o.isCubeTexture&&o.isRenderTargetTexture===!1?-1:1,r.reflectivity.value=a.reflectivity,r.ior.value=a.ior,r.refractionRatio.value=a.refractionRatio),a.lightMap&&(r.lightMap.value=a.lightMap,r.lightMapIntensity.value=a.lightMapIntensity,t(a.lightMap,r.lightMapTransform)),a.aoMap&&(r.aoMap.value=a.aoMap,r.aoMapIntensity.value=a.aoMapIntensity,t(a.aoMap,r.aoMapTransform))}return{refreshFogUniforms:function(r,a){a.color.getRGB(r.fogColor.value,Zc(i)),a.isFog?(r.fogNear.value=a.near,r.fogFar.value=a.far):a.isFogExp2&&(r.fogDensity.value=a.density)},refreshMaterialUniforms:function(r,a,s,o,c){a.isMeshBasicMaterial||a.isMeshLambertMaterial?n(r,a):a.isMeshToonMaterial?(n(r,a),(function(l,h){h.gradientMap&&(l.gradientMap.value=h.gradientMap)})(r,a)):a.isMeshPhongMaterial?(n(r,a),(function(l,h){l.specular.value.copy(h.specular),l.shininess.value=Math.max(h.shininess,1e-4)})(r,a)):a.isMeshStandardMaterial?(n(r,a),(function(l,h){l.metalness.value=h.metalness,h.metalnessMap&&(l.metalnessMap.value=h.metalnessMap,t(h.metalnessMap,l.metalnessMapTransform)),l.roughness.value=h.roughness,h.roughnessMap&&(l.roughnessMap.value=h.roughnessMap,t(h.roughnessMap,l.roughnessMapTransform)),h.envMap&&(l.envMapIntensity.value=h.envMapIntensity)})(r,a),a.isMeshPhysicalMaterial&&(function(l,h,u){l.ior.value=h.ior,h.sheen>0&&(l.sheenColor.value.copy(h.sheenColor).multiplyScalar(h.sheen),l.sheenRoughness.value=h.sheenRoughness,h.sheenColorMap&&(l.sheenColorMap.value=h.sheenColorMap,t(h.sheenColorMap,l.sheenColorMapTransform)),h.sheenRoughnessMap&&(l.sheenRoughnessMap.value=h.sheenRoughnessMap,t(h.sheenRoughnessMap,l.sheenRoughnessMapTransform))),h.clearcoat>0&&(l.clearcoat.value=h.clearcoat,l.clearcoatRoughness.value=h.clearcoatRoughness,h.clearcoatMap&&(l.clearcoatMap.value=h.clearcoatMap,t(h.clearcoatMap,l.clearcoatMapTransform)),h.clearcoatRoughnessMap&&(l.clearcoatRoughnessMap.value=h.clearcoatRoughnessMap,t(h.clearcoatRoughnessMap,l.clearcoatRoughnessMapTransform)),h.clearcoatNormalMap&&(l.clearcoatNormalMap.value=h.clearcoatNormalMap,t(h.clearcoatNormalMap,l.clearcoatNormalMapTransform),l.clearcoatNormalScale.value.copy(h.clearcoatNormalScale),h.side===Xt&&l.clearcoatNormalScale.value.negate())),h.dispersion>0&&(l.dispersion.value=h.dispersion),h.iridescence>0&&(l.iridescence.value=h.iridescence,l.iridescenceIOR.value=h.iridescenceIOR,l.iridescenceThicknessMinimum.value=h.iridescenceThicknessRange[0],l.iridescenceThicknessMaximum.value=h.iridescenceThicknessRange[1],h.iridescenceMap&&(l.iridescenceMap.value=h.iridescenceMap,t(h.iridescenceMap,l.iridescenceMapTransform)),h.iridescenceThicknessMap&&(l.iridescenceThicknessMap.value=h.iridescenceThicknessMap,t(h.iridescenceThicknessMap,l.iridescenceThicknessMapTransform))),h.transmission>0&&(l.transmission.value=h.transmission,l.transmissionSamplerMap.value=u.texture,l.transmissionSamplerSize.value.set(u.width,u.height),h.transmissionMap&&(l.transmissionMap.value=h.transmissionMap,t(h.transmissionMap,l.transmissionMapTransform)),l.thickness.value=h.thickness,h.thicknessMap&&(l.thicknessMap.value=h.thicknessMap,t(h.thicknessMap,l.thicknessMapTransform)),l.attenuationDistance.value=h.attenuationDistance,l.attenuationColor.value.copy(h.attenuationColor)),h.anisotropy>0&&(l.anisotropyVector.value.set(h.anisotropy*Math.cos(h.anisotropyRotation),h.anisotropy*Math.sin(h.anisotropyRotation)),h.anisotropyMap&&(l.anisotropyMap.value=h.anisotropyMap,t(h.anisotropyMap,l.anisotropyMapTransform))),l.specularIntensity.value=h.specularIntensity,l.specularColor.value.copy(h.specularColor),h.specularColorMap&&(l.specularColorMap.value=h.specularColorMap,t(h.specularColorMap,l.specularColorMapTransform)),h.specularIntensityMap&&(l.specularIntensityMap.value=h.specularIntensityMap,t(h.specularIntensityMap,l.specularIntensityMapTransform))})(r,a,c)):a.isMeshMatcapMaterial?(n(r,a),(function(l,h){h.matcap&&(l.matcap.value=h.matcap)})(r,a)):a.isMeshDepthMaterial?n(r,a):a.isMeshDistanceMaterial?(n(r,a),(function(l,h){let u=e.get(h).light;l.referencePosition.value.setFromMatrixPosition(u.matrixWorld),l.nearDistance.value=u.shadow.camera.near,l.farDistance.value=u.shadow.camera.far})(r,a)):a.isMeshNormalMaterial?n(r,a):a.isLineBasicMaterial?((function(l,h){l.diffuse.value.copy(h.color),l.opacity.value=h.opacity,h.map&&(l.map.value=h.map,t(h.map,l.mapTransform))})(r,a),a.isLineDashedMaterial&&(function(l,h){l.dashSize.value=h.dashSize,l.totalSize.value=h.dashSize+h.gapSize,l.scale.value=h.scale})(r,a)):a.isPointsMaterial?(function(l,h,u,d){l.diffuse.value.copy(h.color),l.opacity.value=h.opacity,l.size.value=h.size*u,l.scale.value=.5*d,h.map&&(l.map.value=h.map,t(h.map,l.uvTransform)),h.alphaMap&&(l.alphaMap.value=h.alphaMap,t(h.alphaMap,l.alphaMapTransform)),h.alphaTest>0&&(l.alphaTest.value=h.alphaTest)})(r,a,s,o):a.isSpriteMaterial?(function(l,h){l.diffuse.value.copy(h.color),l.opacity.value=h.opacity,l.rotation.value=h.rotation,h.map&&(l.map.value=h.map,t(h.map,l.mapTransform)),h.alphaMap&&(l.alphaMap.value=h.alphaMap,t(h.alphaMap,l.alphaMapTransform)),h.alphaTest>0&&(l.alphaTest.value=h.alphaTest)})(r,a):a.isShadowMaterial?(r.color.value.copy(a.color),r.opacity.value=a.opacity):a.isShaderMaterial&&(a.uniformsNeedUpdate=!1)}}}function Mm(i,e,t,n){let r={},a={},s=[],o=i.getParameter(i.MAX_UNIFORM_BUFFER_BINDINGS);function c(u,d,p,m){let g=u.value,f=d+"_"+p;if(m[f]===void 0)return m[f]=typeof g=="number"||typeof g=="boolean"?g:g.clone(),!0;{let v=m[f];if(typeof g=="number"||typeof g=="boolean"){if(v!==g)return m[f]=g,!0}else if(v.equals(g)===!1)return v.copy(g),!0}return!1}function l(u){let d={boundary:0,storage:0};return typeof u=="number"||typeof u=="boolean"?(d.boundary=4,d.storage=4):u.isVector2?(d.boundary=8,d.storage=8):u.isVector3||u.isColor?(d.boundary=16,d.storage=12):u.isVector4?(d.boundary=16,d.storage=16):u.isMatrix3?(d.boundary=48,d.storage=48):u.isMatrix4?(d.boundary=64,d.storage=64):u.isTexture?console.warn("THREE.WebGLRenderer: Texture samplers can not be part of an uniforms group."):console.warn("THREE.WebGLRenderer: Unsupported uniform value type.",u),d}function h(u){let d=u.target;d.removeEventListener("dispose",h);let p=s.indexOf(d.__bindingPointIndex);s.splice(p,1),i.deleteBuffer(r[d.id]),delete r[d.id],delete a[d.id]}return{bind:function(u,d){let p=d.program;n.uniformBlockBinding(u,p)},update:function(u,d){let p=r[u.id];p===void 0&&((function(f){let v=f.uniforms,_=0,y=16;for(let w=0,R=v.length;w<R;w++){let B=Array.isArray(v[w])?v[w]:[v[w]];for(let G=0,D=B.length;G<D;G++){let J=B[G],K=Array.isArray(J.value)?J.value:[J.value];for(let V=0,se=K.length;V<se;V++){let X=l(K[V]),ee=_%y,Q=ee%X.boundary,me=ee+Q;_+=Q,me!==0&&y-me<X.storage&&(_+=y-me),J.__data=new Float32Array(X.storage/Float32Array.BYTES_PER_ELEMENT),J.__offset=_,_+=X.storage}}}let S=_%y;S>0&&(_+=y-S),f.__size=_,f.__cache={}})(u),p=(function(f){let v=(function(){for(let w=0;w<o;w++)if(s.indexOf(w)===-1)return s.push(w),w;return console.error("THREE.WebGLRenderer: Maximum number of simultaneously usable uniforms groups reached."),0})();f.__bindingPointIndex=v;let _=i.createBuffer(),y=f.__size,S=f.usage;return i.bindBuffer(i.UNIFORM_BUFFER,_),i.bufferData(i.UNIFORM_BUFFER,y,S),i.bindBuffer(i.UNIFORM_BUFFER,null),i.bindBufferBase(i.UNIFORM_BUFFER,v,_),_})(u),r[u.id]=p,u.addEventListener("dispose",h));let m=d.program;n.updateUBOMapping(u,m);let g=e.render.frame;a[u.id]!==g&&((function(f){let v=r[f.id],_=f.uniforms,y=f.__cache;i.bindBuffer(i.UNIFORM_BUFFER,v);for(let S=0,w=_.length;S<w;S++){let R=Array.isArray(_[S])?_[S]:[_[S]];for(let B=0,G=R.length;B<G;B++){let D=R[B];if(c(D,S,B,y)===!0){let J=D.__offset,K=Array.isArray(D.value)?D.value:[D.value],V=0;for(let se=0;se<K.length;se++){let X=K[se],ee=l(X);typeof X=="number"||typeof X=="boolean"?(D.__data[0]=X,i.bufferSubData(i.UNIFORM_BUFFER,J+V,D.__data)):X.isMatrix3?(D.__data[0]=X.elements[0],D.__data[1]=X.elements[1],D.__data[2]=X.elements[2],D.__data[3]=0,D.__data[4]=X.elements[3],D.__data[5]=X.elements[4],D.__data[6]=X.elements[5],D.__data[7]=0,D.__data[8]=X.elements[6],D.__data[9]=X.elements[7],D.__data[10]=X.elements[8],D.__data[11]=0):(X.toArray(D.__data,V),V+=ee.storage/Float32Array.BYTES_PER_ELEMENT)}i.bufferSubData(i.UNIFORM_BUFFER,J,D.__data)}}}i.bindBuffer(i.UNIFORM_BUFFER,null)})(u),a[u.id]=g)},dispose:function(){for(let u in r)i.deleteBuffer(r[u]);s=[],r={},a={}}}}var al=class{constructor(e={}){let{canvas:t=id(),context:n=null,depth:r=!0,stencil:a=!1,alpha:s=!1,antialias:o=!1,premultipliedAlpha:c=!0,preserveDrawingBuffer:l=!1,powerPreference:h="default",failIfMajorPerformanceCaveat:u=!1,reversedDepthBuffer:d=!1}=e,p;if(this.isWebGLRenderer=!0,n!==null){if(typeof WebGLRenderingContext!="undefined"&&n instanceof WebGLRenderingContext)throw new Error("THREE.WebGLRenderer: WebGL 1 is not supported since r163.");p=n.getContextAttributes().alpha}else p=s;let m=new Uint32Array(4),g=new Int32Array(4),f=null,v=null,_=[],y=[];this.domElement=t,this.debug={checkShaderErrors:!0,onShaderError:null},this.autoClear=!0,this.autoClearColor=!0,this.autoClearDepth=!0,this.autoClearStencil=!0,this.sortObjects=!0,this.clippingPlanes=[],this.localClippingEnabled=!1,this.toneMapping=Pi,this.toneMappingExposure=1,this.transmissionResolutionScale=1;let S=this,w=!1;this._outputColorSpace=Wt;let R=0,B=0,G=null,D=-1,J=null,K=new xt,V=new xt,se=null,X=new Ve(0),ee=0,Q=t.width,me=t.height,ae=1,be=null,Be=null,Ie=new xt(0,0,Q,me),Ne=new xt(0,0,Q,me),le=!1,re=new qi,ne=!1,Oe=!1,Ge=new qe,T=new E,b=new xt,H={background:null,fog:null,environment:null,overrideMaterial:null,isScene:!0},U=!1;function M(){return G===null?ae:1}let A,F,P,te,j,q,he,Se,ue,Re,De,Te,Ue,We,it,Ee,ke,Xe,Tt,Ce,ot,Ke,Ut,Et,N=n;function ut(x,O){return t.getContext(x,O)}try{let x={alpha:!0,depth:r,stencil:a,antialias:o,premultipliedAlpha:c,preserveDrawingBuffer:l,powerPreference:h,failIfMajorPerformanceCaveat:u};if("setAttribute"in t&&t.setAttribute("data-engine",`three.js r${"180"}`),t.addEventListener("webglcontextlost",Mt,!1),t.addEventListener("webglcontextrestored",cn,!1),t.addEventListener("webglcontextcreationerror",Ot,!1),N===null){let O="webgl2";if(N=ut(O,x),N===null)throw ut(O)?new Error("Error creating WebGL context with your selected attributes."):new Error("Error creating WebGL context.")}}catch(x){throw console.error("THREE.WebGLRenderer: "+x.message),x}function Ct(){A=new nf(N),A.init(),Ke=new _m(N,A),F=new Kp(N,A,e,Ke),P=new gm(N,A),F.reversedDepthBuffer&&d&&P.buffers.depth.setReversed(!0),te=new sf(N),j=new sm,q=new vm(N,A,P,j,F,Ke,te),he=new Qp(S),Se=new tf(S),ue=new jp(N),Ut=new Zp(N,ue),Re=new rf(N,ue,te,Ut),De=new lf(N,Re,ue,te),Tt=new of(N,F,q),Ee=new $p(j),Te=new am(S,he,Se,A,F,Ut,Ee),Ue=new xm(S,j),We=new lm,it=new pm(A),Xe=new Yp(S,he,Se,P,De,p,c),ke=new fm(S,De,F),Et=new Mm(N,te,F,P),Ce=new Jp(N,A,te),ot=new af(N,A,te),te.programs=Te.programs,S.capabilities=F,S.extensions=A,S.properties=j,S.renderLists=We,S.shadowMap=ke,S.state=P,S.info=te}Ct();let lt=new dh(S,N);function Mt(x){x.preventDefault(),console.log("THREE.WebGLRenderer: Context Lost."),w=!0}function cn(){console.log("THREE.WebGLRenderer: Context Restored."),w=!1;let x=te.autoReset,O=ke.enabled,$=ke.autoUpdate,ie=ke.needsUpdate,L=ke.type;Ct(),te.autoReset=x,ke.enabled=O,ke.autoUpdate=$,ke.needsUpdate=ie,ke.type=L}function Ot(x){console.error("THREE.WebGLRenderer: A WebGL context could not be created. Reason: ",x.statusMessage)}function An(x){let O=x.target;O.removeEventListener("dispose",An),(function($){(function(ie){let L=j.get(ie).programs;L!==void 0&&(L.forEach(function(z){Te.releaseProgram(z)}),ie.isShaderMaterial&&Te.releaseShaderCache(ie))})($),j.remove($)})(O)}function mi(x,O,$){x.transparent===!0&&x.side===It&&x.forceSinglePass===!1?(x.side=Xt,x.needsUpdate=!0,gn(x,O,$),x.side=oi,x.needsUpdate=!0,gn(x,O,$),x.side=It):gn(x,O,$)}this.xr=lt,this.getContext=function(){return N},this.getContextAttributes=function(){return N.getContextAttributes()},this.forceContextLoss=function(){let x=A.get("WEBGL_lose_context");x&&x.loseContext()},this.forceContextRestore=function(){let x=A.get("WEBGL_lose_context");x&&x.restoreContext()},this.getPixelRatio=function(){return ae},this.setPixelRatio=function(x){x!==void 0&&(ae=x,this.setSize(Q,me,!1))},this.getSize=function(x){return x.set(Q,me)},this.setSize=function(x,O,$=!0){lt.isPresenting?console.warn("THREE.WebGLRenderer: Can't change size while VR device is presenting."):(Q=x,me=O,t.width=Math.floor(x*ae),t.height=Math.floor(O*ae),$===!0&&(t.style.width=x+"px",t.style.height=O+"px"),this.setViewport(0,0,x,O))},this.getDrawingBufferSize=function(x){return x.set(Q*ae,me*ae).floor()},this.setDrawingBufferSize=function(x,O,$){Q=x,me=O,ae=$,t.width=Math.floor(x*$),t.height=Math.floor(O*$),this.setViewport(0,0,x,O)},this.getCurrentViewport=function(x){return x.copy(K)},this.getViewport=function(x){return x.copy(Ie)},this.setViewport=function(x,O,$,ie){x.isVector4?Ie.set(x.x,x.y,x.z,x.w):Ie.set(x,O,$,ie),P.viewport(K.copy(Ie).multiplyScalar(ae).round())},this.getScissor=function(x){return x.copy(Ne)},this.setScissor=function(x,O,$,ie){x.isVector4?Ne.set(x.x,x.y,x.z,x.w):Ne.set(x,O,$,ie),P.scissor(V.copy(Ne).multiplyScalar(ae).round())},this.getScissorTest=function(){return le},this.setScissorTest=function(x){P.setScissorTest(le=x)},this.setOpaqueSort=function(x){be=x},this.setTransparentSort=function(x){Be=x},this.getClearColor=function(x){return x.copy(Xe.getClearColor())},this.setClearColor=function(){Xe.setClearColor(...arguments)},this.getClearAlpha=function(){return Xe.getClearAlpha()},this.setClearAlpha=function(){Xe.setClearAlpha(...arguments)},this.clear=function(x=!0,O=!0,$=!0){let ie=0;if(x){let L=!1;if(G!==null){let z=G.texture.format;L=z===gc||z===mc||z===Ko}if(L){let z=G.texture.type,de=z===ci||z===Mr||z===ca||z===ua||z===Yo||z===Zo,ve=Xe.getClearColor(),ye=Xe.getClearAlpha(),_e=ve.r,we=ve.g,Me=ve.b;de?(m[0]=_e,m[1]=we,m[2]=Me,m[3]=ye,N.clearBufferuiv(N.COLOR,0,m)):(g[0]=_e,g[1]=we,g[2]=Me,g[3]=ye,N.clearBufferiv(N.COLOR,0,g))}else ie|=N.COLOR_BUFFER_BIT}O&&(ie|=N.DEPTH_BUFFER_BIT),$&&(ie|=N.STENCIL_BUFFER_BIT,this.state.buffers.stencil.setMask(4294967295)),N.clear(ie)},this.clearColor=function(){this.clear(!0,!1,!1)},this.clearDepth=function(){this.clear(!1,!0,!1)},this.clearStencil=function(){this.clear(!1,!1,!0)},this.dispose=function(){t.removeEventListener("webglcontextlost",Mt,!1),t.removeEventListener("webglcontextrestored",cn,!1),t.removeEventListener("webglcontextcreationerror",Ot,!1),Xe.dispose(),We.dispose(),it.dispose(),j.dispose(),he.dispose(),Se.dispose(),De.dispose(),Ut.dispose(),Et.dispose(),Te.dispose(),lt.dispose(),lt.removeEventListener("sessionstart",gi),lt.removeEventListener("sessionend",vi),qt.stop()},this.renderBufferDirect=function(x,O,$,ie,L,z){O===null&&(O=H);let de=L.isMesh&&L.matrixWorld.determinant()<0,ve=(function($e,ft,Bt,Je,Ze){ft.isScene!==!0&&(ft=H),q.resetTextureUnits();let $t=ft.fog,tr=Je.isMeshStandardMaterial?ft.environment:null,Cr=G===null?S.outputColorSpace:G.isXRRenderTarget===!0?G.texture.colorSpace:pr,Mn=(Je.isMeshStandardMaterial?Se:he).get(Je.envMap||tr),hn=Je.vertexColors===!0&&!!Bt.attributes.color&&Bt.attributes.color.itemSize===4,Li=!!Bt.attributes.tangent&&(!!Je.normalMap||Je.anisotropy>0),Bn=!!Bt.morphAttributes.position,Pr=!!Bt.morphAttributes.normal,Kn=!!Bt.morphAttributes.color,Di=Pi;Je.toneMapped&&(G!==null&&G.isXRRenderTarget!==!0||(Di=S.toneMapping));let nr=Bt.morphAttributes.position||Bt.morphAttributes.normal||Bt.morphAttributes.color,_a=nr!==void 0?nr.length:0,tt=j.get(Je),kn=v.state.lights;if(ne===!0&&(Oe===!0||$e!==J)){let bt=$e===J&&Je.id===D;Ee.setState(Je,$e,bt)}let Zt=!1;Je.version===tt.__version?tt.needsLights&&tt.lightsStateVersion!==kn.state.version||tt.outputColorSpace!==Cr||Ze.isBatchedMesh&&tt.batching===!1?Zt=!0:Ze.isBatchedMesh||tt.batching!==!0?Ze.isBatchedMesh&&tt.batchingColor===!0&&Ze.colorTexture===null||Ze.isBatchedMesh&&tt.batchingColor===!1&&Ze.colorTexture!==null||Ze.isInstancedMesh&&tt.instancing===!1?Zt=!0:Ze.isInstancedMesh||tt.instancing!==!0?Ze.isSkinnedMesh&&tt.skinning===!1?Zt=!0:Ze.isSkinnedMesh||tt.skinning!==!0?Ze.isInstancedMesh&&tt.instancingColor===!0&&Ze.instanceColor===null||Ze.isInstancedMesh&&tt.instancingColor===!1&&Ze.instanceColor!==null||Ze.isInstancedMesh&&tt.instancingMorph===!0&&Ze.morphTexture===null||Ze.isInstancedMesh&&tt.instancingMorph===!1&&Ze.morphTexture!==null||tt.envMap!==Mn||Je.fog===!0&&tt.fog!==$t?Zt=!0:tt.numClippingPlanes===void 0||tt.numClippingPlanes===Ee.numPlanes&&tt.numIntersection===Ee.numIntersection?(tt.vertexAlphas!==hn||tt.vertexTangents!==Li||tt.morphTargets!==Bn||tt.morphNormals!==Pr||tt.morphColors!==Kn||tt.toneMapping!==Di||tt.morphTargetsCount!==_a)&&(Zt=!0):Zt=!0:Zt=!0:Zt=!0:Zt=!0:(Zt=!0,tt.__version=Je.version);let vn=tt.currentProgram;Zt===!0&&(vn=gn(Je,ft,Ze));let ya=!1,ir=!1,Ir=!1,St=vn.getUniforms(),Sn=tt.uniforms;if(P.useProgram(vn.program)&&(ya=!0,ir=!0,Ir=!0),Je.id!==D&&(D=Je.id,ir=!0),ya||J!==$e){P.buffers.depth.getReversed()&&$e.reversedDepth!==!0&&($e._reversedDepth=!0,$e.updateProjectionMatrix()),St.setValue(N,"projectionMatrix",$e.projectionMatrix),St.setValue(N,"viewMatrix",$e.matrixWorldInverse);let bt=St.map.cameraPosition;bt!==void 0&&bt.setValue(N,T.setFromMatrixPosition($e.matrixWorld)),F.logarithmicDepthBuffer&&St.setValue(N,"logDepthBufFC",2/(Math.log($e.far+1)/Math.LN2)),(Je.isMeshPhongMaterial||Je.isMeshToonMaterial||Je.isMeshLambertMaterial||Je.isMeshBasicMaterial||Je.isMeshStandardMaterial||Je.isShaderMaterial)&&St.setValue(N,"isOrthographic",$e.isOrthographicCamera===!0),J!==$e&&(J=$e,ir=!0,Ir=!0)}if(Ze.isSkinnedMesh){St.setOptional(N,Ze,"bindMatrix"),St.setOptional(N,Ze,"bindMatrixInverse");let bt=Ze.skeleton;bt&&(bt.boneTexture===null&&bt.computeBoneTexture(),St.setValue(N,"boneTexture",bt.boneTexture,q))}Ze.isBatchedMesh&&(St.setOptional(N,Ze,"batchingTexture"),St.setValue(N,"batchingTexture",Ze._matricesTexture,q),St.setOptional(N,Ze,"batchingIdTexture"),St.setValue(N,"batchingIdTexture",Ze._indirectTexture,q),St.setOptional(N,Ze,"batchingColorTexture"),Ze._colorsTexture!==null&&St.setValue(N,"batchingColorTexture",Ze._colorsTexture,q));let Lr=Bt.morphAttributes;Lr.position===void 0&&Lr.normal===void 0&&Lr.color===void 0||Tt.update(Ze,Bt,vn),(ir||tt.receiveShadow!==Ze.receiveShadow)&&(tt.receiveShadow=Ze.receiveShadow,St.setValue(N,"receiveShadow",Ze.receiveShadow)),Je.isMeshGouraudMaterial&&Je.envMap!==null&&(Sn.envMap.value=Mn,Sn.flipEnvMap.value=Mn.isCubeTexture&&Mn.isRenderTargetTexture===!1?-1:1),Je.isMeshStandardMaterial&&Je.envMap===null&&ft.environment!==null&&(Sn.envMapIntensity.value=ft.environmentIntensity),ir&&(St.setValue(N,"toneMappingExposure",S.toneMappingExposure),tt.needsLights&&(Qt=Ir,(Pn=Sn).ambientLightColor.needsUpdate=Qt,Pn.lightProbe.needsUpdate=Qt,Pn.directionalLights.needsUpdate=Qt,Pn.directionalLightShadows.needsUpdate=Qt,Pn.pointLights.needsUpdate=Qt,Pn.pointLightShadows.needsUpdate=Qt,Pn.spotLights.needsUpdate=Qt,Pn.spotLightShadows.needsUpdate=Qt,Pn.rectAreaLights.needsUpdate=Qt,Pn.hemisphereLights.needsUpdate=Qt),$t&&Je.fog===!0&&Ue.refreshFogUniforms(Sn,$t),Ue.refreshMaterialUniforms(Sn,Je,ae,me,v.state.transmissionRenderTarget[$e.id]),pa.upload(N,Cn(tt),Sn,q));var Pn,Qt;if(Je.isShaderMaterial&&Je.uniformsNeedUpdate===!0&&(pa.upload(N,Cn(tt),Sn,q),Je.uniformsNeedUpdate=!1),Je.isSpriteMaterial&&St.setValue(N,"center",Ze.center),St.setValue(N,"modelViewMatrix",Ze.modelViewMatrix),St.setValue(N,"normalMatrix",Ze.normalMatrix),St.setValue(N,"modelMatrix",Ze.matrixWorld),Je.isShaderMaterial||Je.isRawShaderMaterial){let bt=Je.uniformsGroups;for(let rr=0,ar=bt.length;rr<ar;rr++){let sr=bt[rr];Et.update(sr,vn),Et.bind(sr,vn)}}return vn})(x,O,$,ie,L);P.setMaterial(ie,de);let ye=$.index,_e=1;if(ie.wireframe===!0){if(ye=Re.getWireframeAttribute($),ye===void 0)return;_e=2}let we=$.drawRange,Me=$.attributes.position,ze=we.start*_e,ct=(we.start+we.count)*_e;z!==null&&(ze=Math.max(ze,z.start*_e),ct=Math.min(ct,(z.start+z.count)*_e)),ye!==null?(ze=Math.max(ze,0),ct=Math.min(ct,ye.count)):Me!=null&&(ze=Math.max(ze,0),ct=Math.min(ct,Me.count));let et=ct-ze;if(et<0||et===1/0)return;let He;Ut.setup(L,ie,ve,$,ye);let je=Ce;if(ye!==null&&(He=ue.get(ye),je=ot,je.setIndex(He)),L.isMesh)ie.wireframe===!0?(P.setLineWidth(ie.wireframeLinewidth*M()),je.setMode(N.LINES)):je.setMode(N.TRIANGLES);else if(L.isLine){let $e=ie.linewidth;$e===void 0&&($e=1),P.setLineWidth($e*M()),L.isLineSegments?je.setMode(N.LINES):L.isLineLoop?je.setMode(N.LINE_LOOP):je.setMode(N.LINE_STRIP)}else L.isPoints?je.setMode(N.POINTS):L.isSprite&&je.setMode(N.TRIANGLES);if(L.isBatchedMesh)if(L._multiDrawInstances!==null)ea("THREE.WebGLRenderer: renderMultiDrawInstances has been deprecated and will be removed in r184. Append to renderMultiDraw arguments and use indirection."),je.renderMultiDrawInstances(L._multiDrawStarts,L._multiDrawCounts,L._multiDrawCount,L._multiDrawInstances);else if(A.get("WEBGL_multi_draw"))je.renderMultiDraw(L._multiDrawStarts,L._multiDrawCounts,L._multiDrawCount);else{let $e=L._multiDrawStarts,ft=L._multiDrawCounts,Bt=L._multiDrawCount,Je=ye?ue.get(ye).bytesPerElement:1,Ze=j.get(ie).currentProgram.getUniforms();for(let $t=0;$t<Bt;$t++)Ze.setValue(N,"_gl_DrawID",$t),je.render($e[$t]/Je,ft[$t])}else if(L.isInstancedMesh)je.renderInstances(ze,et,L.count);else if($.isInstancedBufferGeometry){let $e=$._maxInstanceCount!==void 0?$._maxInstanceCount:1/0,ft=Math.min($.instanceCount,$e);je.renderInstances(ze,et,ft)}else je.render(ze,et)},this.compile=function(x,O,$=null){$===null&&($=x),v=it.get($),v.init(O),y.push(v),$.traverseVisible(function(L){L.isLight&&L.layers.test(O.layers)&&(v.pushLight(L),L.castShadow&&v.pushShadow(L))}),x!==$&&x.traverseVisible(function(L){L.isLight&&L.layers.test(O.layers)&&(v.pushLight(L),L.castShadow&&v.pushShadow(L))}),v.setupLights();let ie=new Set;return x.traverse(function(L){if(!(L.isMesh||L.isPoints||L.isLine||L.isSprite))return;let z=L.material;if(z)if(Array.isArray(z))for(let de=0;de<z.length;de++){let ve=z[de];mi(ve,$,L),ie.add(ve)}else mi(z,$,L),ie.add(z)}),v=y.pop(),ie},this.compileAsync=function(x,O,$=null){let ie=this.compile(x,O,$);return new Promise(L=>{function z(){ie.forEach(function(de){j.get(de).currentProgram.isReady()&&ie.delete(de)}),ie.size!==0?setTimeout(z,10):L(x)}A.get("KHR_parallel_shader_compile")!==null?z():setTimeout(z,10)})};let Rn=null;function gi(){qt.stop()}function vi(){qt.start()}let qt=new Ud;function Jn(x,O,$,ie){if(x.visible===!1)return;if(x.layers.test(O.layers)){if(x.isGroup)$=x.renderOrder;else if(x.isLOD)x.autoUpdate===!0&&x.update(O);else if(x.isLight)v.pushLight(x),x.castShadow&&v.pushShadow(x);else if(x.isSprite){if(!x.frustumCulled||re.intersectsSprite(x)){ie&&b.setFromMatrixPosition(x.matrixWorld).applyMatrix4(Ge);let z=De.update(x),de=x.material;de.visible&&f.push(x,z,de,$,b.z,null)}}else if((x.isMesh||x.isLine||x.isPoints)&&(!x.frustumCulled||re.intersectsObject(x))){let z=De.update(x),de=x.material;if(ie&&(x.boundingSphere!==void 0?(x.boundingSphere===null&&x.computeBoundingSphere(),b.copy(x.boundingSphere.center)):(z.boundingSphere===null&&z.computeBoundingSphere(),b.copy(z.boundingSphere.center)),b.applyMatrix4(x.matrixWorld).applyMatrix4(Ge)),Array.isArray(de)){let ve=z.groups;for(let ye=0,_e=ve.length;ye<_e;ye++){let we=ve[ye],Me=de[we.materialIndex];Me&&Me.visible&&f.push(x,z,Me,$,b.z,we)}}else de.visible&&f.push(x,z,de,$,b.z,null)}}let L=x.children;for(let z=0,de=L.length;z<de;z++)Jn(L[z],O,$,ie)}function er(x,O,$,ie){let L=x.opaque,z=x.transmissive,de=x.transparent;v.setupLightsView($),ne===!0&&Ee.setGlobalState(S.clippingPlanes,$),ie&&P.viewport(K.copy(ie)),L.length>0&&Yt(L,O,$),z.length>0&&Yt(z,O,$),de.length>0&&Yt(de,O,$),P.buffers.depth.setTest(!0),P.buffers.depth.setMask(!0),P.buffers.color.setMask(!0),P.setPolygonOffset(!1)}function Rr(x,O,$,ie){if(($.isScene===!0?$.overrideMaterial:null)!==null)return;v.state.transmissionRenderTarget[ie.id]===void 0&&(v.state.transmissionRenderTarget[ie.id]=new yn(1,1,{generateMipmaps:!0,type:A.has("EXT_color_buffer_half_float")||A.has("EXT_color_buffer_float")?ha:ci,minFilter:xr,samples:4,stencilBuffer:a,resolveDepthBuffer:!1,resolveStencilBuffer:!1,colorSpace:ht.workingColorSpace}));let L=v.state.transmissionRenderTarget[ie.id],z=ie.viewport||K;L.setSize(z.z*S.transmissionResolutionScale,z.w*S.transmissionResolutionScale);let de=S.getRenderTarget(),ve=S.getActiveCubeFace(),ye=S.getActiveMipmapLevel();S.setRenderTarget(L),S.getClearColor(X),ee=S.getClearAlpha(),ee<1&&S.setClearColor(16777215,.5),S.clear(),U&&Xe.render($);let _e=S.toneMapping;S.toneMapping=Pi;let we=ie.viewport;if(ie.viewport!==void 0&&(ie.viewport=void 0),v.setupLightsView(ie),ne===!0&&Ee.setGlobalState(S.clippingPlanes,ie),Yt(x,$,ie),q.updateMultisampleRenderTarget(L),q.updateRenderTargetMipmap(L),A.has("WEBGL_multisampled_render_to_texture")===!1){let Me=!1;for(let ze=0,ct=O.length;ze<ct;ze++){let et=O[ze],He=et.object,je=et.geometry,$e=et.material,ft=et.group;if($e.side===It&&He.layers.test(ie.layers)){let Bt=$e.side;$e.side=Xt,$e.needsUpdate=!0,xn(He,$,ie,je,$e,ft),$e.side=Bt,$e.needsUpdate=!0,Me=!0}}Me===!0&&(q.updateMultisampleRenderTarget(L),q.updateRenderTargetMipmap(L))}S.setRenderTarget(de,ve,ye),S.setClearColor(X,ee),we!==void 0&&(ie.viewport=we),S.toneMapping=_e}function Yt(x,O,$){let ie=O.isScene===!0?O.overrideMaterial:null;for(let L=0,z=x.length;L<z;L++){let de=x[L],ve=de.object,ye=de.geometry,_e=de.group,we=de.material;we.allowOverride===!0&&ie!==null&&(we=ie),ve.layers.test($.layers)&&xn(ve,O,$,ye,we,_e)}}function xn(x,O,$,ie,L,z){x.onBeforeRender(S,O,$,ie,L,z),x.modelViewMatrix.multiplyMatrices($.matrixWorldInverse,x.matrixWorld),x.normalMatrix.getNormalMatrix(x.modelViewMatrix),L.onBeforeRender(S,O,$,ie,x,z),L.transparent===!0&&L.side===It&&L.forceSinglePass===!1?(L.side=Xt,L.needsUpdate=!0,S.renderBufferDirect($,O,ie,L,x,z),L.side=oi,L.needsUpdate=!0,S.renderBufferDirect($,O,ie,L,x,z),L.side=It):S.renderBufferDirect($,O,ie,L,x,z),x.onAfterRender(S,O,$,ie,L,z)}function gn(x,O,$){O.isScene!==!0&&(O=H);let ie=j.get(x),L=v.state.lights,z=v.state.shadowsArray,de=L.state.version,ve=Te.getParameters(x,L.state,z,O,$),ye=Te.getProgramCacheKey(ve),_e=ie.programs;ie.environment=x.isMeshStandardMaterial?O.environment:null,ie.fog=O.fog,ie.envMap=(x.isMeshStandardMaterial?Se:he).get(x.envMap||ie.environment),ie.envMapRotation=ie.environment!==null&&x.envMap===null?O.environmentRotation:x.envMapRotation,_e===void 0&&(x.addEventListener("dispose",An),_e=new Map,ie.programs=_e);let we=_e.get(ye);if(we!==void 0){if(ie.currentProgram===we&&ie.lightsStateVersion===de)return C(x,ve),we}else ve.uniforms=Te.getUniforms(x),x.onBeforeCompile(ve,S),we=Te.acquireProgram(ve,ye),_e.set(ye,we),ie.uniforms=ve.uniforms;let Me=ie.uniforms;return(x.isShaderMaterial||x.isRawShaderMaterial)&&x.clipping!==!0||(Me.clippingPlanes=Ee.uniform),C(x,ve),ie.needsLights=(function(ze){return ze.isMeshLambertMaterial||ze.isMeshToonMaterial||ze.isMeshPhongMaterial||ze.isMeshStandardMaterial||ze.isShadowMaterial||ze.isShaderMaterial&&ze.lights===!0})(x),ie.lightsStateVersion=de,ie.needsLights&&(Me.ambientLightColor.value=L.state.ambient,Me.lightProbe.value=L.state.probe,Me.directionalLights.value=L.state.directional,Me.directionalLightShadows.value=L.state.directionalShadow,Me.spotLights.value=L.state.spot,Me.spotLightShadows.value=L.state.spotShadow,Me.rectAreaLights.value=L.state.rectArea,Me.ltc_1.value=L.state.rectAreaLTC1,Me.ltc_2.value=L.state.rectAreaLTC2,Me.pointLights.value=L.state.point,Me.pointLightShadows.value=L.state.pointShadow,Me.hemisphereLights.value=L.state.hemi,Me.directionalShadowMap.value=L.state.directionalShadowMap,Me.directionalShadowMatrix.value=L.state.directionalShadowMatrix,Me.spotShadowMap.value=L.state.spotShadowMap,Me.spotLightMatrix.value=L.state.spotLightMatrix,Me.spotLightMap.value=L.state.spotLightMap,Me.pointShadowMap.value=L.state.pointShadowMap,Me.pointShadowMatrix.value=L.state.pointShadowMatrix),ie.currentProgram=we,ie.uniformsList=null,we}function Cn(x){if(x.uniformsList===null){let O=x.currentProgram.getUniforms();x.uniformsList=pa.seqWithValue(O.seq,x.uniforms)}return x.uniformsList}function C(x,O){let $=j.get(x);$.outputColorSpace=O.outputColorSpace,$.batching=O.batching,$.batchingColor=O.batchingColor,$.instancing=O.instancing,$.instancingColor=O.instancingColor,$.instancingMorph=O.instancingMorph,$.skinning=O.skinning,$.morphTargets=O.morphTargets,$.morphNormals=O.morphNormals,$.morphColors=O.morphColors,$.morphTargetsCount=O.morphTargetsCount,$.numClippingPlanes=O.numClippingPlanes,$.numIntersection=O.numClipIntersection,$.vertexAlphas=O.vertexAlphas,$.vertexTangents=O.vertexTangents,$.toneMapping=O.toneMapping}qt.setAnimationLoop(function(x){Rn&&Rn(x)}),typeof self!="undefined"&&qt.setContext(self),this.setAnimationLoop=function(x){Rn=x,lt.setAnimationLoop(x),x===null?qt.stop():qt.start()},lt.addEventListener("sessionstart",gi),lt.addEventListener("sessionend",vi),this.render=function(x,O){if(O!==void 0&&O.isCamera!==!0)return void console.error("THREE.WebGLRenderer.render: camera is not an instance of THREE.Camera.");if(w===!0)return;if(x.matrixWorldAutoUpdate===!0&&x.updateMatrixWorld(),O.parent===null&&O.matrixWorldAutoUpdate===!0&&O.updateMatrixWorld(),lt.enabled===!0&&lt.isPresenting===!0&&(lt.cameraAutoUpdate===!0&&lt.updateCamera(O),O=lt.getCamera()),x.isScene===!0&&x.onBeforeRender(S,x,O,G),v=it.get(x,y.length),v.init(O),y.push(v),Ge.multiplyMatrices(O.projectionMatrix,O.matrixWorldInverse),re.setFromProjectionMatrix(Ge,Ei,O.reversedDepth),Oe=this.localClippingEnabled,ne=Ee.init(this.clippingPlanes,Oe),f=We.get(x,_.length),f.init(),_.push(f),lt.enabled===!0&&lt.isPresenting===!0){let z=S.xr.getDepthSensingMesh();z!==null&&Jn(z,O,-1/0,S.sortObjects)}Jn(x,O,0,S.sortObjects),f.finish(),S.sortObjects===!0&&f.sort(be,Be),U=lt.enabled===!1||lt.isPresenting===!1||lt.hasDepthSensing()===!1,U&&Xe.addToRenderList(f,x),this.info.render.frame++,ne===!0&&Ee.beginShadows();let $=v.state.shadowsArray;ke.render($,x,O),ne===!0&&Ee.endShadows(),this.info.autoReset===!0&&this.info.reset();let ie=f.opaque,L=f.transmissive;if(v.setupLights(),O.isArrayCamera){let z=O.cameras;if(L.length>0)for(let de=0,ve=z.length;de<ve;de++)Rr(ie,L,x,z[de]);U&&Xe.render(x);for(let de=0,ve=z.length;de<ve;de++){let ye=z[de];er(f,x,ye,ye.viewport)}}else L.length>0&&Rr(ie,L,x,O),U&&Xe.render(x),er(f,x,O);G!==null&&B===0&&(q.updateMultisampleRenderTarget(G),q.updateRenderTargetMipmap(G)),x.isScene===!0&&x.onAfterRender(S,x,O),Ut.resetDefaultState(),D=-1,J=null,y.pop(),y.length>0?(v=y[y.length-1],ne===!0&&Ee.setGlobalState(S.clippingPlanes,v.state.camera)):v=null,_.pop(),f=_.length>0?_[_.length-1]:null},this.getActiveCubeFace=function(){return R},this.getActiveMipmapLevel=function(){return B},this.getRenderTarget=function(){return G},this.setRenderTargetTextures=function(x,O,$){let ie=j.get(x);ie.__autoAllocateDepthBuffer=x.resolveDepthBuffer===!1,ie.__autoAllocateDepthBuffer===!1&&(ie.__useRenderToTexture=!1),j.get(x.texture).__webglTexture=O,j.get(x.depthTexture).__webglTexture=ie.__autoAllocateDepthBuffer?void 0:$,ie.__hasExternalTextures=!0},this.setRenderTargetFramebuffer=function(x,O){let $=j.get(x);$.__webglFramebuffer=O,$.__useDefaultFramebuffer=O===void 0};let W=N.createFramebuffer();this.setRenderTarget=function(x,O=0,$=0){G=x,R=O,B=$;let ie=!0,L=null,z=!1,de=!1;if(x){let ve=j.get(x);if(ve.__useDefaultFramebuffer!==void 0)P.bindFramebuffer(N.FRAMEBUFFER,null),ie=!1;else if(ve.__webglFramebuffer===void 0)q.setupRenderTarget(x);else if(ve.__hasExternalTextures)q.rebindTextures(x,j.get(x.texture).__webglTexture,j.get(x.depthTexture).__webglTexture);else if(x.depthBuffer){let we=x.depthTexture;if(ve.__boundDepthTexture!==we){if(we!==null&&j.has(we)&&(x.width!==we.image.width||x.height!==we.image.height))throw new Error("WebGLRenderTarget: Attached DepthTexture is initialized to the incorrect size.");q.setupDepthRenderbuffer(x)}}let ye=x.texture;(ye.isData3DTexture||ye.isDataArrayTexture||ye.isCompressedArrayTexture)&&(de=!0);let _e=j.get(x).__webglFramebuffer;x.isWebGLCubeRenderTarget?(L=Array.isArray(_e[O])?_e[O][$]:_e[O],z=!0):L=x.samples>0&&q.useMultisampledRTT(x)===!1?j.get(x).__webglMultisampledFramebuffer:Array.isArray(_e)?_e[$]:_e,K.copy(x.viewport),V.copy(x.scissor),se=x.scissorTest}else K.copy(Ie).multiplyScalar(ae).floor(),V.copy(Ne).multiplyScalar(ae).floor(),se=le;if($!==0&&(L=W),P.bindFramebuffer(N.FRAMEBUFFER,L)&&ie&&P.drawBuffers(x,L),P.viewport(K),P.scissor(V),P.setScissorTest(se),z){let ve=j.get(x.texture);N.framebufferTexture2D(N.FRAMEBUFFER,N.COLOR_ATTACHMENT0,N.TEXTURE_CUBE_MAP_POSITIVE_X+O,ve.__webglTexture,$)}else if(de){let ve=O;for(let ye=0;ye<x.textures.length;ye++){let _e=j.get(x.textures[ye]);N.framebufferTextureLayer(N.FRAMEBUFFER,N.COLOR_ATTACHMENT0+ye,_e.__webglTexture,$,ve)}}else if(x!==null&&$!==0){let ve=j.get(x.texture);N.framebufferTexture2D(N.FRAMEBUFFER,N.COLOR_ATTACHMENT0,N.TEXTURE_2D,ve.__webglTexture,$)}D=-1},this.readRenderTargetPixels=function(x,O,$,ie,L,z,de,ve=0){if(!x||!x.isWebGLRenderTarget)return void console.error("THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not THREE.WebGLRenderTarget.");let ye=j.get(x).__webglFramebuffer;if(x.isWebGLCubeRenderTarget&&de!==void 0&&(ye=ye[de]),ye){P.bindFramebuffer(N.FRAMEBUFFER,ye);try{let _e=x.textures[ve],we=_e.format,Me=_e.type;if(!F.textureFormatReadable(we))return void console.error("THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not in RGBA or implementation defined format.");if(!F.textureTypeReadable(Me))return void console.error("THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not in UnsignedByteType or implementation defined type.");O>=0&&O<=x.width-ie&&$>=0&&$<=x.height-L&&(x.textures.length>1&&N.readBuffer(N.COLOR_ATTACHMENT0+ve),N.readPixels(O,$,ie,L,Ke.convert(we),Ke.convert(Me),z))}finally{let _e=G!==null?j.get(G).__webglFramebuffer:null;P.bindFramebuffer(N.FRAMEBUFFER,_e)}}},this.readRenderTargetPixelsAsync=async function(x,O,$,ie,L,z,de,ve=0){if(!x||!x.isWebGLRenderTarget)throw new Error("THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not THREE.WebGLRenderTarget.");let ye=j.get(x).__webglFramebuffer;if(x.isWebGLCubeRenderTarget&&de!==void 0&&(ye=ye[de]),ye){if(O>=0&&O<=x.width-ie&&$>=0&&$<=x.height-L){P.bindFramebuffer(N.FRAMEBUFFER,ye);let _e=x.textures[ve],we=_e.format,Me=_e.type;if(!F.textureFormatReadable(we))throw new Error("THREE.WebGLRenderer.readRenderTargetPixelsAsync: renderTarget is not in RGBA or implementation defined format.");if(!F.textureTypeReadable(Me))throw new Error("THREE.WebGLRenderer.readRenderTargetPixelsAsync: renderTarget is not in UnsignedByteType or implementation defined type.");let ze=N.createBuffer();N.bindBuffer(N.PIXEL_PACK_BUFFER,ze),N.bufferData(N.PIXEL_PACK_BUFFER,z.byteLength,N.STREAM_READ),x.textures.length>1&&N.readBuffer(N.COLOR_ATTACHMENT0+ve),N.readPixels(O,$,ie,L,Ke.convert(we),Ke.convert(Me),0);let ct=G!==null?j.get(G).__webglFramebuffer:null;P.bindFramebuffer(N.FRAMEBUFFER,ct);let et=N.fenceSync(N.SYNC_GPU_COMMANDS_COMPLETE,0);return N.flush(),await rd(N,et,4),N.bindBuffer(N.PIXEL_PACK_BUFFER,ze),N.getBufferSubData(N.PIXEL_PACK_BUFFER,0,z),N.deleteBuffer(ze),N.deleteSync(et),z}throw new Error("THREE.WebGLRenderer.readRenderTargetPixelsAsync: requested read bounds are out of range.")}},this.copyFramebufferToTexture=function(x,O=null,$=0){let ie=Math.pow(2,-$),L=Math.floor(x.image.width*ie),z=Math.floor(x.image.height*ie),de=O!==null?O.x:0,ve=O!==null?O.y:0;q.setTexture2D(x,0),N.copyTexSubImage2D(N.TEXTURE_2D,$,0,0,de,ve,L,z),P.unbindTexture()};let oe=N.createFramebuffer(),Z=N.createFramebuffer();this.copyTextureToTexture=function(x,O,$=null,ie=null,L=0,z=null){let de,ve,ye,_e,we,Me,ze,ct,et;z===null&&(L!==0?(ea("WebGLRenderer: copyTextureToTexture function signature has changed to support src and dst mipmap levels."),z=L,L=0):z=0);let He=x.isCompressedTexture?x.mipmaps[z]:x.image;if($!==null)de=$.max.x-$.min.x,ve=$.max.y-$.min.y,ye=$.isBox3?$.max.z-$.min.z:1,_e=$.min.x,we=$.min.y,Me=$.isBox3?$.min.z:0;else{let hn=Math.pow(2,-L);de=Math.floor(He.width*hn),ve=Math.floor(He.height*hn),ye=x.isDataArrayTexture?He.depth:x.isData3DTexture?Math.floor(He.depth*hn):1,_e=0,we=0,Me=0}ie!==null?(ze=ie.x,ct=ie.y,et=ie.z):(ze=0,ct=0,et=0);let je=Ke.convert(O.format),$e=Ke.convert(O.type),ft;O.isData3DTexture?(q.setTexture3D(O,0),ft=N.TEXTURE_3D):O.isDataArrayTexture||O.isCompressedArrayTexture?(q.setTexture2DArray(O,0),ft=N.TEXTURE_2D_ARRAY):(q.setTexture2D(O,0),ft=N.TEXTURE_2D),N.pixelStorei(N.UNPACK_FLIP_Y_WEBGL,O.flipY),N.pixelStorei(N.UNPACK_PREMULTIPLY_ALPHA_WEBGL,O.premultiplyAlpha),N.pixelStorei(N.UNPACK_ALIGNMENT,O.unpackAlignment);let Bt=N.getParameter(N.UNPACK_ROW_LENGTH),Je=N.getParameter(N.UNPACK_IMAGE_HEIGHT),Ze=N.getParameter(N.UNPACK_SKIP_PIXELS),$t=N.getParameter(N.UNPACK_SKIP_ROWS),tr=N.getParameter(N.UNPACK_SKIP_IMAGES);N.pixelStorei(N.UNPACK_ROW_LENGTH,He.width),N.pixelStorei(N.UNPACK_IMAGE_HEIGHT,He.height),N.pixelStorei(N.UNPACK_SKIP_PIXELS,_e),N.pixelStorei(N.UNPACK_SKIP_ROWS,we),N.pixelStorei(N.UNPACK_SKIP_IMAGES,Me);let Cr=x.isDataArrayTexture||x.isData3DTexture,Mn=O.isDataArrayTexture||O.isData3DTexture;if(x.isDepthTexture){let hn=j.get(x),Li=j.get(O),Bn=j.get(hn.__renderTarget),Pr=j.get(Li.__renderTarget);P.bindFramebuffer(N.READ_FRAMEBUFFER,Bn.__webglFramebuffer),P.bindFramebuffer(N.DRAW_FRAMEBUFFER,Pr.__webglFramebuffer);for(let Kn=0;Kn<ye;Kn++)Cr&&(N.framebufferTextureLayer(N.READ_FRAMEBUFFER,N.COLOR_ATTACHMENT0,j.get(x).__webglTexture,L,Me+Kn),N.framebufferTextureLayer(N.DRAW_FRAMEBUFFER,N.COLOR_ATTACHMENT0,j.get(O).__webglTexture,z,et+Kn)),N.blitFramebuffer(_e,we,de,ve,ze,ct,de,ve,N.DEPTH_BUFFER_BIT,N.NEAREST);P.bindFramebuffer(N.READ_FRAMEBUFFER,null),P.bindFramebuffer(N.DRAW_FRAMEBUFFER,null)}else if(L!==0||x.isRenderTargetTexture||j.has(x)){let hn=j.get(x),Li=j.get(O);P.bindFramebuffer(N.READ_FRAMEBUFFER,oe),P.bindFramebuffer(N.DRAW_FRAMEBUFFER,Z);for(let Bn=0;Bn<ye;Bn++)Cr?N.framebufferTextureLayer(N.READ_FRAMEBUFFER,N.COLOR_ATTACHMENT0,hn.__webglTexture,L,Me+Bn):N.framebufferTexture2D(N.READ_FRAMEBUFFER,N.COLOR_ATTACHMENT0,N.TEXTURE_2D,hn.__webglTexture,L),Mn?N.framebufferTextureLayer(N.DRAW_FRAMEBUFFER,N.COLOR_ATTACHMENT0,Li.__webglTexture,z,et+Bn):N.framebufferTexture2D(N.DRAW_FRAMEBUFFER,N.COLOR_ATTACHMENT0,N.TEXTURE_2D,Li.__webglTexture,z),L!==0?N.blitFramebuffer(_e,we,de,ve,ze,ct,de,ve,N.COLOR_BUFFER_BIT,N.NEAREST):Mn?N.copyTexSubImage3D(ft,z,ze,ct,et+Bn,_e,we,de,ve):N.copyTexSubImage2D(ft,z,ze,ct,_e,we,de,ve);P.bindFramebuffer(N.READ_FRAMEBUFFER,null),P.bindFramebuffer(N.DRAW_FRAMEBUFFER,null)}else Mn?x.isDataTexture||x.isData3DTexture?N.texSubImage3D(ft,z,ze,ct,et,de,ve,ye,je,$e,He.data):O.isCompressedArrayTexture?N.compressedTexSubImage3D(ft,z,ze,ct,et,de,ve,ye,je,He.data):N.texSubImage3D(ft,z,ze,ct,et,de,ve,ye,je,$e,He):x.isDataTexture?N.texSubImage2D(N.TEXTURE_2D,z,ze,ct,de,ve,je,$e,He.data):x.isCompressedTexture?N.compressedTexSubImage2D(N.TEXTURE_2D,z,ze,ct,He.width,He.height,je,He.data):N.texSubImage2D(N.TEXTURE_2D,z,ze,ct,de,ve,je,$e,He);N.pixelStorei(N.UNPACK_ROW_LENGTH,Bt),N.pixelStorei(N.UNPACK_IMAGE_HEIGHT,Je),N.pixelStorei(N.UNPACK_SKIP_PIXELS,Ze),N.pixelStorei(N.UNPACK_SKIP_ROWS,$t),N.pixelStorei(N.UNPACK_SKIP_IMAGES,tr),z===0&&O.generateMipmaps&&N.generateMipmap(ft),P.unbindTexture()},this.initRenderTarget=function(x){j.get(x).__webglFramebuffer===void 0&&q.setupRenderTarget(x)},this.initTexture=function(x){x.isCubeTexture?q.setTextureCube(x,0):x.isData3DTexture?q.setTexture3D(x,0):x.isDataArrayTexture||x.isCompressedArrayTexture?q.setTexture2DArray(x,0):q.setTexture2D(x,0),P.unbindTexture()},this.resetState=function(){R=0,B=0,G=null,P.reset(),Ut.reset()},typeof __THREE_DEVTOOLS__!="undefined"&&__THREE_DEVTOOLS__.dispatchEvent(new CustomEvent("observe",{detail:this}))}get coordinateSystem(){return Ei}get outputColorSpace(){return this._outputColorSpace}set outputColorSpace(e){this._outputColorSpace=e;let t=this.getContext();t.drawingBufferColorSpace=ht._getDrawingBufferColorSpace(e),t.unpackColorSpace=ht._getUnpackColorSpace()}};function Rt(i){let e=i>>>0;return function(){e|=0,e=e+1831565813|0;let t=Math.imul(e^e>>>15,1|e);return t=t+Math.imul(t^t>>>7,61|t)^t,((t^t>>>14)>>>0)/4294967296}}var $i=[{key:"golden-hour",label:"Golden Hour",accent:"#fbbf24",accent2:"#fdba74",bg0:"#050816",bg1:"#221a44",beam:"255,214,150",confetti:["#fbbf24","#fdba74","#fff3d6","#ffd700","#a7bedd"]},{key:"nord-sky",label:"Nord Sky",accent:"#38bdf8",accent2:"#7dd3fc",bg0:"#030712",bg1:"#12234a",beam:"150,210,255",confetti:["#38bdf8","#7dd3fc","#e8f7ff","#ffd700","#ffffff"]},{key:"forest-signal",label:"Forest Signal",accent:"#4ade80",accent2:"#86efac",bg0:"#03110b",bg1:"#0a2e20",beam:"150,240,190",confetti:["#4ade80","#86efac","#eafff2","#ffd700","#baf7d0"]},{key:"rose-pulse",label:"Rose Pulse",accent:"#fb7185",accent2:"#fda4af",bg0:"#0d0710",bg1:"#341423",beam:"255,165,185",confetti:["#fb7185","#fda4af","#fff0f2","#ffd700","#ffc2cb"]},{key:"cobalt-stage",label:"Cobalt Stage",accent:"#818cf8",accent2:"#93c5fd",bg0:"#050816",bg1:"#1b2150",beam:"165,175,255",confetti:["#818cf8","#93c5fd","#eef1ff","#ffd700","#c7d2fe"]},{key:"graphite-lime",label:"Graphite Lime",accent:"#a3e635",accent2:"#d9f99d",bg0:"#080a08",bg1:"#1d240f",beam:"205,240,140",confetti:["#a3e635","#d9f99d","#f8ffe8","#ffd700","#e2f8b0"]}];function ga(i){let e=document.documentElement.style;e.setProperty("--accent",i.accent),e.setProperty("--accent-2",i.accent2),e.setProperty("--bg0",i.bg0),e.setProperty("--bg1",i.bg1)}function kd(i){return i.beam.split(",").map(e=>parseInt(e,10)/255)}function fh(i){let e=parseInt(i.slice(1),16);return[(e>>16&255)/255,(e>>8&255)/255,(e&255)/255]}function ol(){let i=null,e=!1,t=!1,n=0,r=0,a=()=>(i||(i=new(window.AudioContext||window.webkitAudioContext)),i),s=()=>{try{a().resume()}catch(l){}};function o(l,h,u,d,p=0){let m=a(),g=m.currentTime+p,f=m.createOscillator(),v=m.createGain();f.type=h,f.frequency.value=l,v.gain.setValueAtTime(0,g),v.gain.linearRampToValueAtTime(u,g+.004),v.gain.exponentialRampToValueAtTime(1e-4,g+d),f.connect(v).connect(m.destination),f.start(g),f.stop(g+d+.05)}function c(l,h,u,d=0){let p=a(),m=p.currentTime+d,g=p.createBiquadFilter();g.type="lowpass",g.Q.value=.8,g.frequency.setValueAtTime(l*5,m),g.frequency.exponentialRampToValueAtTime(l*2.1,m+u);let f=p.createGain();f.gain.setValueAtTime(0,m),f.gain.linearRampToValueAtTime(h,m+.012),f.gain.exponentialRampToValueAtTime(h*.45,m+u*.45),f.gain.exponentialRampToValueAtTime(1e-4,m+u),g.connect(f).connect(p.destination);for(let v of[1,1.006]){let _=p.createOscillator();_.type="sawtooth",_.frequency.value=l*v,_.connect(g),_.start(m),_.stop(m+u+.05)}}return{setCoins(l){e=!!l,e&&s()},setFanfare(l){t=!!l,t&&s()},unlock(){(e||t)&&s()},clink(){if(!e)return;let l=performance.now();if(l-n<45)return;n=l;let h=1700+Math.random()*1600;o(h,"sine",.045,.09),o(h*2.756,"sine",.018,.05)},blip(){e&&(o(660,"triangle",.06,.25),o(990,"triangle",.045,.3,.06))},chime(){e&&[523.25,659.25,783.99,1046.5].forEach((l,h)=>o(l,"triangle",.07,.7,h*.09))},tada(){if(!t)return;let l=performance.now();l-r<1300||(r=l,s(),c(392,.075,.16),c(523.25,.075,.16,.17),c(659.25,.08,.85,.34),c(783.99,.065,.85,.34),c(1046.5,.05,.85,.34),o(2093,"sine",.04,.6,.4))}}}var zd={key:"abstract",label:"Abstract glow",dome:["#26232e","#55525f","#8a8896","#cfc6b8"],hemi:[9147332,1972272,.65],keyL:[16773600,1.5],rimL:[9417983,.8],beamInt:.14,beamColor:"theme",dustColor:"theme",poolColor:"theme",bg:"theme",glassEnv:1,spillR:i=>i.R+.34,archY:-.02,archPedestal:!0,build(i,e){let t=e.R+.42,n=new Le(new gt(t-.1,t,.1,40),new st({color:1314854,roughness:.95,metalness:0,envMapIntensity:.18}));n.position.y=-.07,i.add(n)}};function ll(i,e){let t=document.createElement("canvas");return t.width=i,t.height=e,[t,t.getContext("2d")]}function cl(i){let e=new Ri(i);return e.colorSpace=Wt,e.anisotropy=4,e}function jt(i,e,t){let[n,r]=ll(i,e);return t(r,i,e),cl(n)}var Gt=26,Zn=17,Sm=new E(0,1,0),mh=`
  varying vec2 vUv; varying vec3 vN; varying vec3 vV;
  void main() {
    vUv = uv;
    vec4 wp = modelMatrix * vec4(position, 1.0);
    vN = normalize(mat3(modelMatrix) * normal);
    vV = normalize(cameraPosition - wp.xyz);
    gl_Position = projectionMatrix * viewMatrix * wp;
  }`,gh=`
  varying vec2 vUv; varying vec3 vN; varying vec3 vV;
  uniform float uInt; uniform vec3 uColor;
  void main() {
    float axis = pow(abs(dot(normalize(vN), normalize(vV))), 1.3);
    float grad = pow(vUv.y, 1.7);
    gl_FragColor = vec4(uColor, uInt * grad * axis);
  }`;function ui(i,e,t,n={}){let r=Rt(n.seed||3),a=n.planks||9;i.fillStyle=n.base||"#3f2a18",i.fillRect(0,0,e,t);for(let s=0;s<a;s++){let o=(r()-.5)*(n.light||24);i.fillStyle=o>0?`rgba(255,214,160,${o/255})`:`rgba(0,0,0,${-o/255})`;let c=n.horizontal?0:e/a*s,l=n.horizontal?t/a*s:0;i.fillRect(c,l,n.horizontal?e:e/a+1,n.horizontal?t/a+1:t),i.strokeStyle="rgba(16,8,3,0.3)",i.lineWidth=1;for(let h=0;h<3;h++){let u=r();i.beginPath();for(let d=0;d<=6;d++){let p=d/6,m=n.horizontal?e*p:c+e/a*u+Math.sin(p*6+u*9)*2,g=n.horizontal?l+t/a*u+Math.sin(p*6+u*9)*2:t*p;d?i.lineTo(m,g):i.moveTo(m,g)}i.stroke()}}i.fillStyle="rgba(0,0,0,0.5)";for(let s=1;s<a;s++)n.horizontal?i.fillRect(0,t/a*s-1,e,2):i.fillRect(e/a*s-1,0,2,t)}function di(i,e,t,n,r){let a=jt(2048,512,n);a.wrapS=Xi,a.repeat.x=-1;let s=new gt(i,i,t-e,48,1,!0,r?Math.PI-r/2:0,r||Math.PI*2),o=new Le(s,new st({map:a,roughness:.95,metalness:0,envMapIntensity:.2,side:It}));return o.position.y=(e+t)/2,o}function pi(i,e,t,n={}){let r=new Le(new Ci(i,48),new st({map:jt(1024,1024,t),roughness:n.rough!==void 0?n.rough:.9,metalness:0,envMapIntensity:n.env!==void 0?n.env:.25}));return r.rotation.x=-Math.PI/2,r.position.y=e,r}function hl(i,e,t){let n=new Le(new Ci(i,32),new Ft({color:t}));return n.rotation.x=Math.PI/2,n.position.y=e,n}function ps(i,e,t){return new Le(new Wn(i,10,8),new Ft({color:new Ve(e).multiplyScalar(t)}))}function vh(i,e,t){let n=new Le(new on(i*2,i*2),new Ft({map:jt(128,128,r=>{let a=r.createRadialGradient(64,64,4,64,64,62);a.addColorStop(0,`rgba(${e},${t})`),a.addColorStop(1,`rgba(${e},0)`),r.fillStyle=a,r.fillRect(0,0,128,128)}),transparent:!0,depthWrite:!1,blending:Xn}));return n.rotation.x=-Math.PI/2,n}function _h(i,e,t,n){let r=new E().subVectors(e,i),a=new Le(new gt(t,t,r.length(),8),n);return a.position.copy(i).add(e).multiplyScalar(.5),a.quaternion.setFromUnitVectors(Sm,r.normalize()),a}function Hd(i,e){let t=Math.max(1.35,e.R+.3),n=3.55,r=new Le(new gt(t,t*.94,.16,36),new st({map:jt(256,256,(o,c,l)=>ui(o,c,l,{base:"#38200e",planks:6,seed:11})),roughness:.7,envMapIntensity:.3}));r.position.y=-.1,i.add(r);let a=new st({color:3021840,roughness:.8});for(let o=0;o<4;o++){let c=o/4*Math.PI*2+Math.PI/4;i.add(_h(new E(Math.cos(c)*t*.55,-.14,Math.sin(c)*t*.55),new E(Math.cos(c)*t*.92,-.1-n,Math.sin(c)*t*.92),.07,a))}let s=new Le(new Ki(t*.8,.028,8,32),new st({color:10517045,metalness:.8,roughness:.4}));return s.rotation.x=Math.PI/2,s.position.y=-.1-n*.62,i.add(s),-.1-n}function fs(i,e,t,n,r={}){let a=new pn,s=new Le(new gt(.09,.55,.5,20,1,!0),new st({color:r.shade||2046508,roughness:.5,metalness:.3,side:It})),o=ps(.14,16761722,r.glow!==void 0?r.glow:2.6);o.position.y=-.16;let c=(r.toCeil!==void 0?r.toCeil:Zn)-t-.25,l=new Le(new gt(.018,.018,c,6),new st({color:854536,roughness:.9}));l.position.y=c/2+.25,a.add(s,o,l),a.position.set(e,t,n),i.add(a)}function ul(i,e,t,n,r,a){let s=new ai(new Wn(.085,8,6),new Ft({color:new Ve(16765066).multiplyScalar(a||2.4)}),r),o=new qe,c=new E;for(let l=0;l<r;l++){let h=(l+.5)/r;c.lerpVectors(e,t,h),c.y-=Math.sin(h*Math.PI)*n,o.setPosition(c),s.setMatrixAt(l,o)}i.add(s)}function Ii(i,e,t,n,r){let a=new st({color:1839110,roughness:.9}),s=2.6,o=r||1.5,c=new Le(new gt(o,o*.96,.12,20),a);c.position.set(e,n+s,t);let l=new Le(new gt(.1,.16,s,8),a);l.position.set(e,n+s/2,t),i.add(c,l);let h=ps(.09,16757854,2.2);h.position.set(e,n+s+.2,t),i.add(h);let u=vh(1,"255,180,94",.5);u.position.set(e,n+s+.08,t),i.add(u)}function yh(i,e,t,n,r){let a=new E(0,r.topY*.5,0),s=a.clone().sub(e),o=s.length(),c=new Le(new gt(.24,1.6,o,24,1,!0),new Dt({transparent:!0,depthWrite:!1,blending:Xn,side:It,uniforms:{uInt:{value:n},uColor:{value:new E(t[0],t[1],t[2])}},vertexShader:mh,fragmentShader:gh}));c.quaternion.setFromUnitVectors(new E(0,-1,0),s.clone().normalize()),c.position.copy(e).add(a).multiplyScalar(.5),c.frustumCulled=!1,i.add(c);let l=ps(.22,new Ve(t[0],t[1],t[2]).getHex(),2.4);l.position.copy(e),i.add(l)}function bm(i,e,t){let n=Rt(31),r=i.createLinearGradient(0,0,0,t);r.addColorStop(0,"#040a07"),r.addColorStop(.55,"#0d2018"),r.addColorStop(1,"#1a3d30"),i.fillStyle=r,i.fillRect(0,0,e,t);let a=t*.71;for(let p=0;p<7;p++){let m=e*(.02+p*.145+n()*.03),g=i.createRadialGradient(m,a-68,6,m,a-68,120);g.addColorStop(0,"rgba(255,190,105,0.55)"),g.addColorStop(1,"rgba(255,190,105,0)"),i.fillStyle=g,i.fillRect(m-120,a-188,240,240),i.fillStyle="#ffdba0",i.fillRect(m-3,a-74,6,12)}for(let p=0;p<6;p++){let m=e*(.09+p*.15)+n()*40,g=54+n()*46,f=60+n()*36,v=a-118-n()*46;i.fillStyle="#8a6a2c",i.fillRect(m-4,v-4,g+8,f+8),i.fillStyle=`rgb(${30+n()*30|0},${26+n()*20|0},${20+n()*16|0})`,i.fillRect(m,v,g,f)}let s=e*.5,o=e*.17,c=a-175,l=i.createRadialGradient(s,a-70,20,s,a-70,o);l.addColorStop(0,"rgba(255,176,84,0.6)"),l.addColorStop(1,"rgba(255,176,84,0)"),i.fillStyle=l,i.fillRect(s-o,a-70-o,o*2,o*2),i.fillStyle="#241408",i.fillRect(s-o*.72,c,o*1.44,a-c);for(let p of[a-18,a-95]){i.fillStyle="#3a2410",i.fillRect(s-o*.66,p,o*1.32,8);let m=s-o*.6;for(;m<s+o*.58;){let g=34+n()*24,f=9+n()*6;i.fillStyle=["#1a3a20","#4a2408","#28160a","#183048"][n()*4|0],i.fillRect(m,p-g,f,g),i.fillRect(m+f*.32,p-g-8,f*.36,9),i.fillStyle="rgba(255,210,130,0.85)",i.fillRect(m+1.5,p-g+4,2.5,g*.55),m+=f+5+n()*7}}let h=e*.77,u=a-168;i.strokeStyle="#a8842f",i.lineWidth=6,i.strokeRect(h,u,130,96),i.fillStyle="#101c14",i.fillRect(h+3,u+3,124,90),i.fillStyle="#c9a44a",i.textAlign="center",i.textBaseline="middle",i.font="700 26px Georgia, serif",i.fillText("LIVE",h+65,u+34),i.fillText("TIPS",h+65,u+66),i.fillStyle="#2c1b0d",i.fillRect(0,a,e,t-a);for(let p=0;p<e;p+=13)i.fillStyle=`rgba(255,205,150,${.02+n()*.05})`,i.fillRect(p,a,11,t-a),i.fillStyle="rgba(0,0,0,0.45)",i.fillRect(p+11,a,2,t-a);i.fillStyle="#54351a",i.fillRect(0,a,e,6),i.fillStyle="rgba(0,0,0,0.5)",i.fillRect(0,a+6,e,4);let d=i.createLinearGradient(0,t-40,0,t);d.addColorStop(0,"rgba(0,0,0,0)"),d.addColorStop(1,"rgba(0,0,0,0.5)"),i.fillStyle=d,i.fillRect(0,t-40,e,40)}var Gd={key:"pub",label:"Irish pub",dome:["#170e07","#3c2513","#77491e","#dfa04b"],hemi:[16763274,2757640,.62],keyL:[16768174,1.35],rimL:[16751181,.6],beamInt:.11,beamColor:[1,.73,.38],dustColor:[1,.73,.38],poolColor:"255,196,120",bg:["#241206","#120a04","#070402"],glassEnv:.7,spillR:i=>Math.max(1.35,i.R+.3)-.08,archY:-3.65,build(i,e){let t=Hd(i,e);i.add(pi(Gt+.6,t-.01,(n,r,a)=>ui(n,r,a,{base:"#221507",planks:22,horizontal:!0,light:20,seed:21}))),i.add(di(Gt,t,Zn,bm)),i.add(hl(Gt,Zn,722436)),fs(i,0,e.topY+1.95,0,{glow:3}),fs(i,-3.4,3.1,-4.6,{glow:2.2}),fs(i,3.8,2.9,-5.2,{glow:2.2}),fs(i,-4.6,3.3,3.6,{glow:2.2}),Ii(i,-7.5,-10.5,t,1.7),Ii(i,6.8,-12,t,1.7),Ii(i,12,-4.5,t,1.6),Ii(i,-12.5,3.5,t,1.6)}};function Tm(i,e,t){i.fillStyle="#5a1020",i.fillRect(0,0,e,t);for(let r=0;r<e;r++){let a=.5+.5*Math.sin(r*.085+Math.sin(r*.011)*2.2);i.fillStyle=`rgb(${34+a*148|0},${4+a*26|0},${12+a*34|0})`,i.fillRect(r,0,1,t)}for(let[r,a,s]of[[.2,.66,.2],[.5,.6,.26],[.82,.68,.2]]){let o=i.createRadialGradient(e*r,t*a,20,e*r,t*a,300);o.addColorStop(0,`rgba(255,178,150,${s})`),o.addColorStop(1,"rgba(255,178,150,0)"),i.fillStyle=o,i.fillRect(e*r-300,t*a-300,600,600)}i.fillStyle="rgba(0,0,0,0.4)",i.fillRect(0,0,e,t*.11),i.fillStyle="#c9a44a",i.fillRect(0,t*.11,e,4);let n=i.createLinearGradient(0,t*.82,0,t);n.addColorStop(0,"rgba(0,0,0,0)"),n.addColorStop(1,"rgba(0,0,0,0.6)"),i.fillStyle=n,i.fillRect(0,t*.82,e,t*.18)}function Em(i,e,t){i.fillStyle="#111013",i.fillRect(0,0,e,t),i.fillStyle="#1b191e",i.fillRect(10,10,e-20,t-20),i.strokeStyle="#43464d",i.lineWidth=4,i.strokeRect(5,5,e-10,t-10),i.strokeStyle="rgba(0,0,0,0.7)",i.lineWidth=2,i.strokeRect(11,11,e-22,t-22),i.fillStyle="#565a62",i.fillRect(e/2-20,t/2-26,40,52),i.fillStyle="#2d3036",i.fillRect(e/2-10,t/2-15,20,30)}var Vd={key:"concert",label:"Concert stage",dome:["#140a0e","#371420","#6d2331","#e6b160"],hemi:[14192808,2099732,.55],keyL:[16769732,1.45],rimL:[16734860,.9],beamInt:.17,beamColor:"theme",dustColor:"theme",poolColor:"theme",bg:["#1c060d","#0d0308","#040104"],glassEnv:1,spillR:i=>Math.max(2.6,i.R*2+.7)/2-.12,archY:-1.92,build(i,e){let t=Math.max(2.6,e.R*2+.7),n=1.9,r=new Le(new sn(t,n,t),new st({map:jt(256,256,Em),roughness:.55,metalness:.25,envMapIntensity:.5}));r.position.y=-.02-n/2,i.add(r);let a=-.02-n;i.add(pi(Gt+.6,a-.01,(l,h,u)=>ui(l,h,u,{base:"#0e0a08",planks:20,horizontal:!0,light:9,seed:43}),{rough:.5,env:.22})),i.add(di(Gt,a,Zn,Tm));let s=26,o=new ai(new Wn(.2,8,6),new Ft({color:new Ve(16760430).multiplyScalar(2.6)}),s),c=new qe;for(let l=0;l<s;l++){let h=l/s*Math.PI*2;c.setPosition(Math.cos(h)*8.5,5+Math.sin(h*3)*.4,Math.sin(h)*8.5),o.setMatrixAt(l,c)}i.add(o),yh(i,new E(-5.5,7.4,-2.8),[1,.55,.2],.17,e),yh(i,new E(5.5,7.4,-2.4),[.85,.25,.55],.17,e)}};function wm(i){let e=i.createLinearGradient(0,0,0,512);e.addColorStop(0,"#04060d"),e.addColorStop(.55,"#0a1120"),e.addColorStop(1,"#18243c"),i.fillStyle=e,i.fillRect(0,0,512,512);let t=Rt(77);i.fillStyle="#fff";for(let r=0;r<110;r++){let a=t()*512,s=t()*300,o=t();i.globalAlpha=.12+o*.5,i.fillRect(a,s,o>.85?2:1,o>.85?2:1)}i.globalAlpha=1;let n=i.createRadialGradient(392,86,4,392,86,60);n.addColorStop(0,"rgba(234,240,255,0.95)"),n.addColorStop(.16,"rgba(215,226,255,0.85)"),n.addColorStop(.2,"rgba(190,205,240,0.25)"),n.addColorStop(1,"rgba(190,205,240,0)"),i.fillStyle=n,i.fillRect(0,0,512,512)}function Am(i,e,t){let n=Rt(41);i.fillStyle="#221c19",i.fillRect(0,0,e,t);let r=46,a=20;for(let o=0;o*a<t;o++)for(let c=-1;c*r<e;c++){let l=c*r+(o%2?r/2:0),h=n();i.fillStyle=`rgb(${52+h*26|0},${34+h*16|0},${27+h*10|0})`,i.fillRect(l+1,o*a+1,r-2,a-2)}let s=i.createLinearGradient(0,t,0,t-160);s.addColorStop(0,"rgba(0,0,0,0.7)"),s.addColorStop(1,"rgba(0,0,0,0)"),i.fillStyle=s,i.fillRect(0,t-160,e,160),s=i.createLinearGradient(0,0,0,140),s.addColorStop(0,"rgba(0,0,0,0.75)"),s.addColorStop(1,"rgba(0,0,0,0)"),i.fillStyle=s,i.fillRect(0,0,e,140);for(let[o,c,l]of[[.3,.34,1],[.6,.28,.85],[.74,.42,.7]]){let h=e*o,u=t*c,d=46*l,p=60*l,m=i.createRadialGradient(h+d/2,u+p/2,5,h+d/2,u+p/2,120*l);m.addColorStop(0,"rgba(255,190,110,0.4)"),m.addColorStop(1,"rgba(255,190,110,0)"),i.fillStyle=m,i.fillRect(h-120,u-120,d+240,p+240),i.fillStyle="#ffca82",i.fillRect(h,u,d,p),i.fillStyle="rgba(60,30,10,0.8)",i.fillRect(h+d/2-2,u,4,p),i.fillRect(h,u+p/2-2,d,4)}i.textAlign="center",i.textBaseline="middle";for(let[o,c,l]of[[.42,"LIVE",-.05],[.55,"GIG",.07],[.68,"SHOW",-.08]])i.save(),i.translate(e*o,t*.72),i.rotate(l),i.fillStyle="#cfc4ae",i.fillRect(-34,-46,68,92),i.fillStyle="#2a2118",i.font="800 24px Georgia, serif",i.fillText(c,0,-14),i.font="700 13px Georgia, serif",i.fillText("TONIGHT",0,16),i.restore()}function Rm(i,e,t){let n=Rt(29);i.fillStyle="#0b0d11",i.fillRect(0,0,e,t);let r=38;for(let s=0;s*r<t+r;s++)for(let o=-1;o*r<e+r;o++){let c=o*r+(s%2?r/2:0)+(n()-.5)*5,l=s*r+(n()-.5)*5,h=n();i.fillStyle=`rgb(${22+h*14|0},${24+h*14|0},${30+h*16|0})`,i.beginPath(),i.roundRect(c+2,l+2,r-4,r-4,10),i.fill(),i.fillStyle=`rgba(180,200,235,${.02+h*.035})`,i.beginPath(),i.roundRect(c+5,l+4,r-10,7,4),i.fill()}let a=i.createRadialGradient(512,512,120,512,512,512);a.addColorStop(0,"rgba(0,0,0,0)"),a.addColorStop(1,"rgba(0,0,0,0.65)"),i.fillStyle=a,i.fillRect(0,0,e,t)}var Wd={key:"street",label:"Night street",dome:["#0a0d15","#1b2434","#3c4d69","#96abd0"],hemi:[10335464,1119263,.55],keyL:[13490687,1.3],rimL:[16761722,.75],beamInt:.07,beamColor:[.62,.74,1],dustColor:[.62,.74,1],poolColor:"170,195,255",bg:wm,glassEnv:1,spillR:i=>Math.max(2.7,i.R*2+.6)/2-.12,archY:-2.52,build(i,e){let t=Math.max(2.7,e.R*2+.6),n=2.5,r=new Le(new sn(t,n,t),new st({map:jt(256,256,(f,v,_)=>{ui(f,v,_,{base:"#5a4023",planks:5,light:34,seed:17}),f.strokeStyle="rgba(30,18,8,0.8)",f.lineWidth=10,f.strokeRect(8,8,v-16,_-16),f.fillStyle="rgba(20,12,5,0.55)",f.font="700 44px Georgia, serif",f.textAlign="center",f.textBaseline="middle",f.fillText("TIPS",v/2,_/2)}),roughness:.85,envMapIntensity:.25}));r.position.y=-.02-n/2,i.add(r);let a=-.02-n;i.add(pi(Gt+.6,a-.01,Rm,{rough:.72,env:.3})),i.add(di(Gt,a,Zn,Am,Math.PI*1.34));let s=new st({color:1316380,roughness:.6,metalness:.5}),o=-4,c=-3.1,l=9.6,h=new Le(new gt(.09,.13,l,10),s);h.position.set(o,a+l/2,c),i.add(h);let u=new E(-o,0,-c).normalize(),d=new E(o,a+l,c).addScaledVector(u,1.7);i.add(_h(new E(o,a+l,c),d.clone(),.055,s));let p=new Le(new gt(.16,.5,.35,12,1,!0),new st({color:1316380,roughness:.5,metalness:.5,side:It}));p.position.copy(d),i.add(p);let m=ps(.2,16767394,3);m.position.copy(d).y-=.14,i.add(m);let g=vh(2.8,"255,205,130",.34);g.position.set(d.x,a+.02,d.z),i.add(g)}};function Cm(i,e,t){let n=Rt(83),r=c=>t-(c+.065)/10.065*t,a=e/(Math.PI*2*Gt)/(t/10.065);i.fillStyle="#93a294",i.fillRect(0,0,e,t);let s=15;for(let c=0;c<t;c+=s)for(let l=0;l<e;l+=s){let h=(n()-.5)*26;i.fillStyle=h>0?`rgba(255,255,250,${h/255})`:`rgba(30,40,32,${-h/255})`,i.fillRect(l,c,s-1,s-1)}i.fillStyle="rgba(20,26,20,0.35)";for(let c=s-1;c<t;c+=s)i.fillRect(0,c,e,1);for(let c=s-1;c<e;c+=s)i.fillRect(c,0,1,t);let o=i.createLinearGradient(0,0,0,t*.45);o.addColorStop(0,"rgba(8,11,9,0.75)"),o.addColorStop(1,"rgba(8,11,9,0)"),i.fillStyle=o,i.fillRect(0,0,e,t*.45),o=i.createLinearGradient(0,t,0,t-90),o.addColorStop(0,"rgba(28,24,14,0.5)"),o.addColorStop(1,"rgba(28,24,14,0)"),i.fillStyle=o,i.fillRect(0,t-90,e,90);for(let c=0;c<46;c++){let l=n()*e,h=3+n()*12,u=n()*t*.5;i.fillStyle=`rgba(24,30,24,${.03+n()*.06})`,i.fillRect(l,u,h,t-u)}i.fillStyle="#2c3f33",i.fillRect(0,r(1.95),e,r(1.5)-r(1.95)),i.fillStyle="rgba(255,255,255,0.1)",i.fillRect(0,r(1.95),e,2);for(let c of[.1,.42,.78]){i.save(),i.translate(e*c,t),i.scale(a,1);let l=145,h=r(3.2)-t;i.fillStyle="#0a0d0b",i.beginPath(),i.moveTo(-l/2,0),i.lineTo(-l/2,h+l/2),i.arc(0,h+l/2,l/2,Math.PI,0),i.lineTo(l/2,0),i.fill(),i.strokeStyle="rgba(200,215,200,0.22)",i.lineWidth=5,i.stroke(),i.restore()}i.textAlign="center",i.textBaseline="middle";for(let[c,l]of[[.24,"EXIT  \u2192"],[.64,"\u2190  TRAINS"]]){let h=e*c,u=r(2.35);i.fillStyle="#16337a",i.fillRect(h-92,u-22,184,44),i.strokeStyle="#e8edf4",i.lineWidth=2.5,i.strokeRect(h-87,u-17,174,34),i.fillStyle="#f2f5fa",i.font="700 23px Arial, sans-serif",i.fillText(l,h,u+1)}i.save(),i.translate(e*.52,r(2.5)),i.scale(a,1),i.fillStyle="#1d4ea3",i.beginPath(),i.arc(0,0,58,0,7),i.fill(),i.strokeStyle="#eef2f8",i.lineWidth=6,i.beginPath(),i.arc(0,0,50,0,7),i.stroke(),i.fillStyle="#f4f7fb",i.font="800 64px Georgia, serif",i.fillText("M",0,4),i.restore();for(let[c,l,h]of[[.33,"LIVE",-.06],[.71,"GIG",.05],[.88,"SALE",-.04]])i.save(),i.translate(e*c,r(1.25)),i.scale(a,1),i.rotate(h),i.fillStyle="#cfc8b6",i.fillRect(-34,-46,68,92),i.fillStyle="#2a2420",i.font="800 21px Georgia, serif",i.fillText(l,0,-14),i.font="700 12px Georgia, serif",i.fillText("TONIGHT",0,14),i.restore()}function Pm(i,e,t){let n=Rt(89);i.fillStyle="#26292c",i.fillRect(0,0,e,t);let r=60;for(let s=0;s<t;s+=r)for(let o=0;o<e;o+=r){let c=(n()-.5)*16;i.fillStyle=c>0?`rgba(210,220,226,${c/255})`:`rgba(4,6,8,${-c/255})`,i.fillRect(o+1,s+1,r-2,r-2)}for(let s=0;s<14;s++)i.fillStyle=`rgba(12,14,12,${.04+n()*.05})`,i.beginPath(),i.ellipse(n()*e,n()*t,24+n()*90,16+n()*60,n()*3,0,7),i.fill();let a=i.createRadialGradient(512,512,60,512,512,520);a.addColorStop(0,"rgba(255,255,255,0.04)"),a.addColorStop(.6,"rgba(255,255,255,0)"),a.addColorStop(1,"rgba(0,0,0,0.55)"),i.fillStyle=a,i.fillRect(0,0,e,t)}function Im(i,e,t){let n=Rt(97);i.fillStyle="#1c201d",i.fillRect(0,0,e,t);for(let r=0;r<30;r++)i.fillStyle=`rgba(0,0,0,${.05+n()*.08})`,i.beginPath(),i.ellipse(n()*e,n()*t,30+n()*80,20+n()*50,n()*3,0,7),i.fill();for(let r of[86,200,314,428]){let a=i.createLinearGradient(0,r-34,0,r+34);a.addColorStop(0,"rgba(210,235,220,0)"),a.addColorStop(.5,"rgba(210,235,220,0.22)"),a.addColorStop(1,"rgba(210,235,220,0)"),i.fillStyle=a,i.fillRect(0,r-34,e,68),i.fillStyle="#dfe8e2",i.fillRect(0,r-6,e,12)}}function Lm(i,e,t){let n=Rt(101);i.fillStyle="#8b998c",i.fillRect(0,0,e,t);let r=26;for(let s=0;s<t;s+=r)for(let o=0;o<e;o+=r){let c=(n()-.5)*24;i.fillStyle=c>0?`rgba(255,255,250,${c/255})`:`rgba(30,40,32,${-c/255})`,i.fillRect(o,s,r-1,r-1)}i.fillStyle="rgba(20,26,20,0.35)";for(let s=r-1;s<t;s+=r)i.fillRect(0,s,e,1);for(let s=r-1;s<e;s+=r)i.fillRect(s,0,1,t);i.fillStyle="#23262a",i.fillRect(0,t-40,e,40);let a=i.createLinearGradient(0,0,0,60);a.addColorStop(0,"rgba(10,14,11,0.5)"),a.addColorStop(1,"rgba(10,14,11,0)"),i.fillStyle=a,i.fillRect(0,0,e,60);for(let s=0;s<10;s++){let o=n()*e;i.fillStyle=`rgba(24,30,24,${.04+n()*.05})`,i.fillRect(o,n()*t*.4,4+n()*8,t)}}function Dm(i,e,t){let n=Rt(103);i.fillStyle="#6e5330",i.fillRect(0,0,e,t);for(let r=0;r<24;r++)i.fillStyle=`rgba(${n()>.5?"40,26,10":"190,165,120"},${.03+n()*.04})`,i.beginPath(),i.ellipse(n()*e,n()*t,12+n()*40,8+n()*24,n()*3,0,7),i.fill();i.strokeStyle="rgba(46,30,12,0.55)",i.lineWidth=3,i.beginPath(),i.moveTo(0,t*.52),i.lineTo(e,t*.5),i.stroke(),i.fillStyle="rgba(200,188,160,0.3)",i.fillRect(e*.62,0,26,t),i.strokeStyle="rgba(46,30,12,0.65)",i.lineWidth=8,i.strokeRect(2,2,e-4,t-4)}var Xd={key:"metro",label:"Metro underpass",dome:["#101211","#242a26","#47524b","#9fb3a7"],hemi:[13625564,1316634,.5],keyL:[15269874,1.05],rimL:[9414911,.55],beamInt:.09,beamColor:[.72,.85,.78],dustColor:[.72,.85,.78],poolColor:"190,215,200",bg:["#202622","#121613","#070908"],glassEnv:1,spillR:i=>Math.max(2.7,i.R*2+.8)*.41-.05,archY:-.065,build(i,e){let r=Math.max(2.7,e.R*2+.8),a=new Le(new sn(r,.045,r*.82),new st({map:jt(256,192,Dm),roughness:.94,envMapIntensity:.1}));a.position.y=-.0425,a.rotation.y=.16,i.add(a),i.add(pi(Gt+.6,-.065,Pm,{rough:.55,env:.35})),i.add(di(Gt,-.065,10,Cm));let s=new Le(new Ci(Gt,40),new Ft({map:jt(512,512,Im),side:It}));s.rotation.x=Math.PI/2,s.position.y=10,i.add(s);let o=new st({map:jt(256,512,Lm),roughness:.6,envMapIntensity:.3});for(let[c,l]of[[-7,-7.5],[7.5,-8],[-9.5,3.5],[8.5,6]]){let h=new Le(new sn(1.35,10.065,1.35),o);h.position.set(c,(10+-.065)/2,l),i.add(h)}for(let[c,l,h,u]of[[0,6.9,-4.2,.4],[-5,6.7,-.5,1.25],[4.6,7.1,2.8,-.5]]){let d=new pn,p=new Le(new sn(2.6,.09,.24),new st({color:2764332,roughness:.7})),m=new Le(new sn(2.4,.055,.1),new Ft({color:new Ve(15007721).multiplyScalar(2.3)}));m.position.y=-.06,d.add(p,m),d.position.set(c,l,h),d.rotation.y=u,i.add(d)}}};function Um(i,e,t){let n=Rt(53),r=i.createLinearGradient(0,0,0,t);r.addColorStop(0,"#150c06"),r.addColorStop(.55,"#2e1e10"),r.addColorStop(1,"#402c18"),i.fillStyle=r,i.fillRect(0,0,e,t);for(let c=0;c<60;c++)i.fillStyle=`rgba(${n()>.5?"255,220,180":"0,0,0"},${.02+n()*.04})`,i.beginPath(),i.ellipse(n()*e,n()*t,30+n()*90,20+n()*60,n()*3,0,7),i.fill();let a=t*.75;for(let c=0;c<6;c++){let l=e*(.06+c*.16+n()*.03),h=i.createRadialGradient(l,a-60,8,l,a-60,150);h.addColorStop(0,"rgba(255,196,120,0.5)"),h.addColorStop(1,"rgba(255,196,120,0)"),i.fillStyle=h,i.fillRect(l-150,a-210,300,300),i.fillStyle="#ffe2b0",i.fillRect(l-3,a-66,6,12)}let s=e*.5-110,o=a-205;i.fillStyle="#4a3018",i.fillRect(s-10,o-10,240,180),i.fillStyle="#141a14",i.fillRect(s,o,220,160),i.fillStyle="rgba(226,238,226,0.85)",i.font="700 34px Georgia, serif",i.textAlign="center",i.textBaseline="middle",i.fillText("MENU",s+110,o+36),i.strokeStyle="rgba(226,238,226,0.5)",i.lineWidth=3;for(let c=0;c<4;c++)i.beginPath(),i.moveTo(s+26,o+70+c*22),i.lineTo(s+194-n()*40,o+70+c*22),i.stroke();for(let c of[.2,.78]){let l=e*c-130,h=a-130;i.fillStyle="#5a3a1c",i.fillRect(l,h,260,9);for(let u=0;u<4;u++){let d=l+20+u*62,p=.7+n()*.5;i.fillStyle="#7a4a22",i.fillRect(d,h-22*p,26*p,22*p),i.fillStyle="#2e5424",i.beginPath(),i.arc(d+13*p,h-30*p,16*p,0,7),i.fill(),i.beginPath(),i.arc(d+4*p,h-24*p,10*p,0,7),i.fill(),i.beginPath(),i.arc(d+23*p,h-24*p,10*p,0,7),i.fill()}}}var jd={key:"cafe",label:"Cozy caf\xE9",dome:["#1b120a","#40301c","#775833","#e7c184"],hemi:[16767400,2890254,.78],keyL:[16769981,1.3],rimL:[16756832,.5],beamInt:0,beamColor:[1,.8,.5],dustColor:[1,.8,.5],poolColor:"255,200,130",bg:["#211308","#140b04","#080401"],glassEnv:.7,spillR:i=>Math.max(2,i.R+.55)-.12,archY:-3.32,build(i,e){let t=Math.max(2,e.R+.55),n=3.3,r=new Le(new gt(t,t*.97,.14,40),new st({map:jt(512,512,(l,h,u)=>ui(l,h,u,{base:"#5a3a1c",planks:8,light:26,seed:71})),roughness:.55,envMapIntensity:.45}));r.position.y=-.09,i.add(r);let a=new st({color:1841689,roughness:.5,metalness:.6}),s=new Le(new gt(.14,.14,n-.3,12),a);s.position.y=-.16-(n-.3)/2,i.add(s);let o=-.02-n,c=new Le(new gt(1,1.15,.12,24),a);c.position.y=o+.06,i.add(c),i.add(pi(Gt+.6,o-.01,(l,h,u)=>ui(l,h,u,{base:"#2c1c0e",planks:13,horizontal:!0,light:22,seed:77}))),i.add(di(Gt,o,Zn,Um)),i.add(hl(Gt,Zn,1182213)),ul(i,new E(-6.5,5.2,-3.8),new E(7,4.6,-3),1.6,30),ul(i,new E(-5.5,4.2,-5.6),new E(6.5,5,-5.2),1.4,26),ul(i,new E(-7,4.4,2.8),new E(7.5,5.2,1.6),1.8,32),Ii(i,-6.5,-9.5,o,1.5),Ii(i,7.2,-10.5,o,1.5),Ii(i,11.5,-2.5,o,1.4)}};var dl=[zd,Gd,Vd,Wd,Xd,jd];var va=.21/25.75;var pl=[{key:"caviar",kind:"jar",label:"Caviar jar \u2014 95 ml",liters:.095,bodyD:71,bodyH:52,neckD:56,target:20},{key:"tin",kind:"mug",label:"Tin can \u2014 0.3 L",liters:.3,bodyD:78,bodyH:84,fill:.92,target:50},{key:"mug",kind:"mug",label:"Beer mug \u2014 0.5 L",liters:.5,bodyD:82,bodyH:98,fill:.97,target:100,handle:!0},{key:"jar05",kind:"jar",label:"Jar \u2014 0.5 L",liters:.5,bodyD:86,bodyH:130,neckD:66,target:125},{key:"jar1",kind:"jar",label:"Jar \u2014 1 L",liters:1,bodyD:106,bodyH:166,neckD:76,target:250},{key:"jar2",kind:"jar",label:"Jar \u2014 2 L",liters:2,bodyD:122,bodyH:214,neckD:82,target:500},{key:"stage",kind:"stage",label:"Stage jar \u2014 stylized 2 L",target:500},{key:"jar3",kind:"jar",label:"Jar \u2014 3 L",liters:3,bodyD:153,bodyH:242,neckD:84,target:1e3},{key:"jar5",kind:"jar",label:"Pickle jar \u2014 5 L",liters:5,bodyD:170,bodyH:290,neckD:110,target:1500},{key:"bucket",kind:"bucket",label:"Bucket \u2014 10 L",liters:10,bodyD:260,bodyH:230,botD:220,fill:.96,target:3e3},{key:"bowl",kind:"sphere",label:"Fishbowl \u2014 20 L",liters:20,bodyD:340,bodyH:330,neckD:180,fill:.64,target:6e3}],qd="stage";function xh(i){if(i.kind==="stage")return{key:i.key,kind:"jar",stage:!0,liters:2,target:i.target,R:.84*.84,wall:.06*.84,coinH:.032,layerStep:.052,density:.66,wallTop:2.55*.84,shoulderEnd:2.9*.84,neckR:.554*.84,topY:3.28*.84,fillBottom:.16*.84,fillTop:2.88*.84,mouthR:.49*.84,centerY:1.66*.84,camSpan:3.95*.84+.35,rIn(s){if(s<=2.55*.84)return .78*.84;if(s>=2.9*.84)return .505*.84;let o=(s-2.55*.84)/(.35*.84),c=o*o*(3-2*o);return(.78+(.505-.78)*c)*.84}};let e=i.bodyD/2*va,t=i.bodyH*va,n=Math.max(.02,Math.min(.04,e*.07)),r={key:i.key,kind:i.kind,liters:i.liters,target:i.target,handle:i.handle,R:e,H:t,wall:n,coinH:.018,layerStep:.018*1.42,density:.86,fillBottom:n+.05};if(i.kind==="jar"){let a=i.neckD/2*va,s=Math.max(.06,Math.min(t*.18,(e-a)*1.2+.04)),o=Math.max(.05,Math.min(15*va,t*.2));r.wallTop=t-s-o,r.shoulderEnd=r.wallTop+s,r.neckR=a,r.topY=t,r.fillTop=Math.max(r.wallTop*.9,r.shoulderEnd-s*.35),r.mouthR=a-n*.8,r.rIn=c=>{let l=e-n,h=a-n*.8;if(c<=r.wallTop)return l;if(c>=r.shoulderEnd)return h;let u=(c-r.wallTop)/(r.shoulderEnd-r.wallTop),d=u*u*(3-2*u);return l+(h-l)*d}}else if(i.kind==="mug")r.topY=t,r.fillTop=t*(i.fill||.88),r.mouthR=e-n,r.rIn=()=>e-n;else if(i.kind==="bucket"){let a=i.botD/2*va;r.rBot=a,r.topY=t,r.fillTop=t*(i.fill||.9),r.mouthR=e-n,r.rIn=s=>a+(e-a)*Math.min(1,Math.max(0,s/t))-n}else{let a=i.neckD/2*va,s=e*.92;r.cy=s,r.mouthR=a,r.topY=s+Math.sqrt(Math.max(.01,e*e-a*a)),r.fillTop=s+e*(i.fill||.5),r.rIn=o=>Math.sqrt(Math.max(4e-4,e*e-(o-s)*(o-s)))-n}return r.centerY=r.topY*.5,r.camSpan=r.topY+1.1,r}function Mh(i){let e=[],t=(n,r)=>e.push(new pe(Math.max(.001,n),r));if(i.kind==="jar"){let{R:n,wallTop:r,shoulderEnd:a,neckR:s,topY:o}=i,c=Math.min(.05,(o-a)*.45);t(.001,0),t(n*.8,0),t(n*.95,n*.06),t(n,n*.2),t(n,r),t(n*.96,r+(a-r)*.4),t((n+s)*.5,r+(a-r)*.8),t(s*1.02,a),t(s,a+.01),t(s,o-c),t(s*1.09,o-c*.6),t(s*1.09,o-c*.15),t(s,o),t(s*.88,o)}else if(i.kind==="mug"){let{R:n,topY:r}=i;t(.001,0),t(n*.85,0),t(n,n*.15),t(n,r-.02),t(n*1.04,r-.01),t(n*1.04,r),t(n*.9,r)}else if(i.kind==="bucket"){let{R:n,rBot:r,topY:a}=i;t(.001,0),t(r*.9,0),t(r,.04),t(n,a-.03),t(n*1.06,a-.015),t(n*1.06,a),t(n*.93,a)}else{let{R:n,cy:r,mouthR:a,topY:s}=i,o=Math.asin(Math.max(-1,(0-r)/n)),c=Math.asin(Math.min(1,(s-r)/n));t(.001,0);for(let l=0;l<=22;l++){let h=o+(c-o)*(l/22);t(Math.cos(h)*n,r+Math.sin(h)*n)}t(a*.9,s)}return e}var Nm=[15778398,16174188,14856012],Fm=[13732432,12876866,14523492],Om=[16777215,15856113,15329769],fl=[16777215,16184042,15724527],ml={b5:{n:"5",bg:"#bcc0c5",dk:"#565b61",band:"#dfe2e6"},b10:{n:"10",bg:"#d89b94",dk:"#8a4a44",band:"#eecfcb"},b20:{n:"20",bg:"#92aed6",dk:"#40608c",band:"#d3e0f0"},b50:{n:"50",bg:"#e0a95e",dk:"#8f6222",band:"#f2ddb4"}};function Sh(i,e){let[t,n]=ll(128,128),r=n.createRadialGradient(50,46,10,64,64,86);if(e?(r.addColorStop(0,"#eef0f3"),r.addColorStop(.72,"#d6dade"),r.addColorStop(1,"#a9afb7")):(r.addColorStop(0,"#ffffff"),r.addColorStop(.72,"#efefef"),r.addColorStop(1,"#c8c8c8")),n.fillStyle=r,n.fillRect(0,0,128,128),e){let a=n.createRadialGradient(56,54,6,64,64,40);a.addColorStop(0,"#f4d98c"),a.addColorStop(.8,"#e2b04f"),a.addColorStop(1,"#bb8d33"),n.fillStyle=a,n.beginPath(),n.arc(64,64,38,0,7),n.fill(),n.strokeStyle="rgba(96,82,48,0.5)",n.lineWidth=2,n.beginPath(),n.arc(64,64,38,0,7),n.stroke()}n.strokeStyle="rgba(84,84,88,0.5)",n.lineWidth=4,n.beginPath(),n.arc(64,64,58,0,7),n.stroke(),n.fillStyle="rgba(88,88,92,0.5)";for(let a=0;a<12;a++){let s=a/12*Math.PI*2;n.beginPath(),n.arc(64+Math.cos(s)*49,64+Math.sin(s)*49,2.6,0,7),n.fill()}return n.font="800 46px Georgia, serif",n.textAlign="center",n.textBaseline="middle",n.fillStyle="rgba(255,255,255,0.5)",n.fillText(i,65.5,67.5),n.fillStyle=e?"rgba(80,60,22,0.72)":"rgba(70,70,72,0.6)",n.fillText(i,64,66),cl(t)}function gl(i){let[e,t]=ll(256,128);return t.fillStyle=i.bg,t.fillRect(0,0,256,128),t.fillStyle=i.band,t.fillRect(150,8,62,112),t.strokeStyle=i.dk,t.globalAlpha=.55,t.lineWidth=3,t.strokeRect(7,7,242,114),t.globalAlpha=.35,t.lineWidth=1.5,t.strokeRect(13,13,230,102),t.globalAlpha=.5,t.lineWidth=4,t.beginPath(),t.moveTo(42,102),t.lineTo(42,62),t.arc(70,62,28,Math.PI,0),t.lineTo(98,102),t.stroke(),t.globalAlpha=.3,t.lineWidth=2.5,t.beginPath(),t.moveTo(52,102),t.lineTo(52,64),t.arc(70,64,18,Math.PI,0),t.lineTo(88,102),t.stroke(),t.globalAlpha=1,t.fillStyle=i.dk,t.textAlign="center",t.textBaseline="middle",t.font="900 46px Georgia, serif",t.fillText(i.n,222,94),t.font="900 26px Georgia, serif",t.fillText(i.n,28,27),cl(e)}function Bm(i){let e=new on(i.billW,i.billH,12,5),t=e.attributes.position;for(let n=0;n<t.count;n++){let r=t.getX(n),a=t.getY(n),s=Math.sin(r*91.7+a*57.3)*43758.5453,o=.02*Math.sin(r*12)+.016*Math.sin(a*16+r*6)+(s-Math.floor(s)-.5)*.014;t.setZ(n,o)}return e.computeVertexNormals(),e}function Yd(i){return{BUCKETS:[{key:"gold",kind:"coin",value:.5,map:Sh("50",!1),side:14606046,tints:Nm,scale:[.88,.97]},{key:"copper",kind:"coin",value:.05,map:Sh("5",!1),side:14606046,tints:Fm,scale:[.78,.86]},{key:"bi",kind:"coin",value:2,map:Sh("2",!0),side:14080734,tints:Om,scale:[.98,1.06]},{key:"b5",kind:"bill",value:5,map:gl(ml.b5),tints:fl},{key:"b10",kind:"bill",value:10,map:gl(ml.b10),tints:fl},{key:"b20",kind:"bill",value:20,map:gl(ml.b20),tints:fl},{key:"b50",kind:"bill",value:50,map:gl(ml.b50),tints:fl}],billGeo:Bm(i)}}function Zd(i){let e={ready:!1};function t(){let s=(o,c)=>new Dt({depthTest:!1,depthWrite:!1,blending:li,uniforms:c,vertexShader:"varying vec2 vUv; void main() { vUv = uv; gl_Position = vec4(position.xy, 0.0, 1.0); }",fragmentShader:o});e.rtScene=new yn(2,2,{samples:4}),e.rtA=new yn(2,2),e.rtB=new yn(2,2),e.bright=s(`varying vec2 vUv; uniform sampler2D tex;
      void main() {
        vec3 c = texture2D(tex, vUv).rgb;
        float l = dot(c, vec3(0.299, 0.587, 0.114));
        gl_FragColor = vec4(c * smoothstep(0.68, 0.98, l), 1.0);
      }`,{tex:{value:null}}),e.blur=s(`varying vec2 vUv; uniform sampler2D tex; uniform vec2 uDir;
      void main() {
        vec3 s = texture2D(tex, vUv).rgb * 0.227027;
        vec2 o1 = uDir * 1.3846, o2 = uDir * 3.2308;
        s += (texture2D(tex, vUv + o1).rgb + texture2D(tex, vUv - o1).rgb) * 0.316216;
        s += (texture2D(tex, vUv + o2).rgb + texture2D(tex, vUv - o2).rgb) * 0.070270;
        gl_FragColor = vec4(s, 1.0);
      }`,{tex:{value:null},uDir:{value:new pe}}),e.comp=s(`varying vec2 vUv;
      uniform sampler2D tScene; uniform sampler2D tBloom; uniform float uStr;
      void main() {
        vec3 c = texture2D(tScene, vUv).rgb + texture2D(tBloom, vUv).rgb * uStr;
        gl_FragColor = vec4(pow(c, vec3(0.4545)), 1.0);
      }`,{tScene:{value:null},tBloom:{value:null},uStr:{value:.45}}),e.quad=new Le(new on(2,2),e.bright),e.scene=new ji,e.scene.add(e.quad),e.cam=new vr(-1,1,1,-1,0,1),e.ready=!0}function n(){if(!e.ready)return;let s=i.getDrawingBufferSize(new pe);e.rtScene.setSize(s.x,s.y),e.rtA.setSize(Math.max(2,s.x>>1),Math.max(2,s.y>>1)),e.rtB.setSize(Math.max(2,s.x>>1),Math.max(2,s.y>>1))}function r(s,o){e.quad.material=s,i.setRenderTarget(o),i.render(e.scene,e.cam)}function a(s,o){e.ready||(t(),n()),i.setRenderTarget(e.rtScene),i.render(s,o),e.bright.uniforms.tex.value=e.rtScene.texture,r(e.bright,e.rtA);let c=1/e.rtA.width,l=1/e.rtA.height;for(let h=1;h<=2;h++)e.blur.uniforms.tex.value=e.rtA.texture,e.blur.uniforms.uDir.value.set(c*h,0),r(e.blur,e.rtB),e.blur.uniforms.tex.value=e.rtB.texture,e.blur.uniforms.uDir.value.set(0,l*h),r(e.blur,e.rtA);e.comp.uniforms.tScene.value=e.rtScene.texture,e.comp.uniforms.tBloom.value=e.rtA.texture,r(e.comp,null)}return{render:a,resize:n}}var Qi={coinR:.105,billW:.5,billH:.26,billRatio:.1,gravity:14,dprMax:1.75};function Jd(i){let{host:e,emit:t}=i,n=i.config||{},r=!!i.reduced,a=Rt(20260703),s=$i.find(I=>I.key===n.theme)||$i[0];ga(s);let o=s.confetti.map(fh),c=ol();c.setCoins(!!n.sound),c.setFanfare(!!n.tipSound);let l=pl.find(I=>I.key===n.vessel)||pl.find(I=>I.key===qd),h=xh(l),u=dl.find(I=>I.key===n.scene)||dl[0],d=!!n.notes,p={top:0,bottom:0,...n.insets||{}},m=Math.max(0,Math.floor(i.state&&i.state.bankedJars||0)),g=0,f=-1;function v(I){s=I,ga(I),y(),o=I.confetti.map(fh)}function _(I){return I==="theme"?kd(s):I}function y(){let I=_(u.beamColor);if(F&&F.uniforms.uColor.value.set(I[0],I[1],I[2]),q){let k=_(u.dustColor);q.uniforms.uColor.value.set(k[0],k[1],k[2])}T&&H(),K()}let S=new al({antialias:!0,alpha:!0,powerPreference:"high-performance"});S.setPixelRatio(Math.min(devicePixelRatio||1,Qi.dprMax)),S.toneMapping=Vo,S.toneMappingExposure=1.06,e.appendChild(S.domElement);let w=new ji,R=new rn(36,1,.1,50),B=new E(0,1.55,0);function G(I){let k=new ji,Y=document.createElement("canvas");Y.width=4,Y.height=256;let fe=Y.getContext("2d"),ge=fe.createLinearGradient(0,256,0,0);ge.addColorStop(0,I[0]),ge.addColorStop(.45,I[1]),ge.addColorStop(.8,I[2]),ge.addColorStop(1,I[3]),fe.fillStyle=ge,fe.fillRect(0,0,4,256);let ce=new Ri(Y);ce.colorSpace=Wt,k.add(new Le(new Wn(20,16,12),new Ft({map:ce,side:Xt})));let xe=(vt,Lt,wt,$n,In,Nr,Ma)=>{let Sa=new Le(new on(wt,$n),new Ft({color:new Ve(vt).multiplyScalar(Lt),side:It}));Sa.position.set(In,Nr,Ma),Sa.lookAt(0,0,0),k.add(Sa)};xe(16773853,12,7,4,0,8,0),xe(16775406,7,4,1.4,2.5,4,6),xe(13623551,4,3,7,-8,2,2),xe(16765160,3.5,3,7,8,1,-2),xe(3355460,1.5,14,14,0,-6,0);let Fe=new fa(S),nt=Fe.fromScene(k,0).texture;return Fe.dispose(),nt}w.environment=G(u.dome);let D=null,J=null;function K(){D||(D=document.createElement("canvas"),D.width=D.height=512,J=new Ri(D),J.colorSpace=Wt);let I=D.getContext("2d");if(typeof u.bg=="function")u.bg(I);else{let k=u.bg==="theme"?[s.bg1,"#14101f",s.bg0]:u.bg,Y=I.createRadialGradient(256,118,30,256,180,520);Y.addColorStop(0,k[0]),Y.addColorStop(.52,k[1]),Y.addColorStop(1,k[2]),I.fillStyle=Y,I.fillRect(0,0,512,512)}J.needsUpdate=!0,w.background=J}K();let V=new as(u.hemi[0],u.hemi[1],u.hemi[2]);w.add(V);let se=new sa(u.keyL[0],u.keyL[1]);se.position.set(3,6,2.5),w.add(se);let X=new sa(u.rimL[0],u.rimL[1]);X.position.set(-3,3.5,-4),w.add(X);function ee(){w.environment&&w.environment.dispose(),w.environment=G(u.dome),V.color.setHex(u.hemi[0]),V.groundColor.setHex(u.hemi[1]),V.intensity=u.hemi[2],se.color.setHex(u.keyL[0]),se.intensity=u.keyL[1],X.color.setHex(u.rimL[0]),X.intensity=u.rimL[1],y()}let Q=[];function me(){for(let ge of Q)w.remove(ge),ge.geometry.dispose(),ge.material.dispose();let I=u.glassEnv,k=new Ji(Mh(h),48),Y=new Le(k,new st({color:12573160,roughness:.06,metalness:0,transparent:!0,opacity:.055,side:Xt,depthWrite:!1,envMapIntensity:.5*I}));Y.renderOrder=1;let fe=new Le(k,new st({color:14479096,roughness:.05,metalness:0,transparent:!0,opacity:.09,side:oi,depthWrite:!1,envMapIntensity:1.55*I}));if(fe.renderOrder=2,Q=[Y,fe],w.add(Y,fe),h.handle){let ge=ae(I);Q.push(...ge),w.add(...ge)}}function ae(I){let k=h.topY*.3,Y=2.8,fe=new Ki(k,.042,12,32,Y),ge=(Fe,nt,vt,Lt)=>{let wt=new Le(fe,new st({color:nt,roughness:.05,metalness:0,transparent:!0,opacity:vt,side:Fe,depthWrite:!1,envMapIntensity:Lt*I}));return wt.position.set(h.R-k*Math.cos(Y/2)-.02,h.topY*.5,0),wt.rotation.z=-Y/2,wt},ce=ge(Xt,12573160,.07,.5);ce.renderOrder=1;let xe=ge(oi,14479096,.16,1.55);return xe.renderOrder=2,[ce,xe]}function be(I,k,Y){let fe=Rt(9);I.fillStyle="#4a350f",I.fillRect(0,0,k,Y);let ge=["#b98c33","#a87e2e","#93702a","#9c6432","#a9adb3","#c29b3f"];for(let ce=0;ce<150;ce++){let xe=fe()*k,Fe=fe()*Y,nt=10+fe()*10;I.fillStyle=ge[fe()*ge.length|0],I.beginPath(),I.arc(xe,Fe,nt,0,7),I.fill(),I.strokeStyle="rgba(40,24,4,0.7)",I.lineWidth=2.5,I.stroke(),I.fillStyle="rgba(255,236,190,0.16)",I.beginPath(),I.arc(xe-nt*.3,Fe-nt*.3,nt*.4,0,7),I.fill()}}function Be(){let I=new pn,k=u.glassEnv,Y=new Ji(Mh(h),32),fe=new Le(Y,new st({color:12573160,roughness:.06,metalness:0,transparent:!0,opacity:.055,side:Xt,depthWrite:!1,envMapIntensity:.5*k}));fe.renderOrder=1;let ge=new Le(Y,new st({color:14479096,roughness:.05,metalness:0,transparent:!0,opacity:.09,side:oi,depthWrite:!1,envMapIntensity:1.55*k}));ge.renderOrder=2;let ce=[new pe(.001,.03)];for(let Lt=0;Lt<=12;Lt++){let wt=.03+(h.fillTop-.03)*(Lt/12);ce.push(new pe(Math.max(.01,h.rIn(wt)-.012),wt))}let xe=Math.max(.02,h.rIn(h.fillTop)-.012);ce.push(new pe(xe*.66,h.fillTop+xe*.08)),ce.push(new pe(.001,h.fillTop+xe*.12));let Fe=jt(256,256,be);Fe.wrapS=Fe.wrapT=Xi,Fe.repeat.set(3,Math.max(1,Math.round(h.fillTop*1.2)));let nt=new Le(new Ji(ce,24),new st({map:Fe,color:13608274,roughness:.5,metalness:.42,envMapIntensity:.45})),vt=new Le(new on(h.R*2.9,h.R*2.9),new Ft({map:jt(64,64,Lt=>{let wt=Lt.createRadialGradient(32,32,4,32,32,31);wt.addColorStop(0,"rgba(0,0,10,0.5)"),wt.addColorStop(1,"rgba(0,0,10,0)"),Lt.fillStyle=wt,Lt.fillRect(0,0,64,64)}),transparent:!0,depthWrite:!1}));return vt.rotation.x=-Math.PI/2,vt.position.y=.015,I.add(vt,nt,fe,ge),h.handle&&I.add(...ae(k)),I.scale.setScalar(.85),I}let Ie=5;function Ne(I){let k=[4.05,5.37,3.52,5.9,4.71][I%Ie],Y=Math.max(7,h.R*2+5.2)+I%3*.6,fe=u.archY!==void 0?u.archY:-.02;return new E(Math.cos(k)*Y,fe,Math.sin(k)*Y)}let le=null,re=null;function ne(I){le&&U(le),re=null,le=new pn;let k=Math.min(Ie,m);for(let Y=0;Y<k;Y++){if(Y===I)continue;let fe=Be();fe.position.copy(Ne(Y)),fe.rotation.y=Y*1.7%(Math.PI*2),le.add(fe),u.archPedestal&&le.add(Oe(fe.position))}w.add(le)}function Oe(I){let k=new Le(new gt(h.R*.9+.22,h.R+.28,.09,28),new st({color:1314854,roughness:.95,metalness:0,envMapIntensity:.18}));return k.position.set(I.x,I.y-.065,I.z),k}let Ge=null,T=null,b=null;function H(){let I=u.poolColor==="theme"?s.beam:u.poolColor,k=Ge.getContext("2d");if(k.clearRect(0,0,256,256),u.beamInt>0){let fe=k.createRadialGradient(128,128,10,128,128,126);fe.addColorStop(0,`rgba(${I},0.30)`),fe.addColorStop(.55,`rgba(${I},0.10)`),fe.addColorStop(1,`rgba(${I},0)`),k.fillStyle=fe,k.fillRect(0,0,256,256)}let Y=k.createRadialGradient(128,128,8,128,128,52);Y.addColorStop(0,"rgba(0,0,12,0.55)"),Y.addColorStop(1,"rgba(0,0,12,0)"),k.fillStyle=Y,k.fillRect(0,0,256,256),T.needsUpdate=!0}function U(I){w.remove(I),I.traverse(k=>{if(k.isInstancedMesh&&k.dispose(),k.geometry&&k.geometry.dispose(),k.material)for(let Y of Array.isArray(k.material)?k.material:[k.material])Y.map&&Y.map.dispose(),Y.dispose()})}let M=null;function A(){M&&U(M),M=new pn,u.build(M,h),w.add(M),ne(),b||(Ge=document.createElement("canvas"),Ge.width=Ge.height=256,T=new Ri(Ge),H(),b=new Le(new on(3.4,3.4),new Ft({map:T,transparent:!0,depthWrite:!1})),b.rotation.x=-Math.PI/2,b.position.y=.012,w.add(b)),b.scale.setScalar(Math.max(.55,(h.R+1)/1.85)),P&&(P.visible=u.beamInt>0),he&&(he.visible=u.beamInt>0)}let F=null,P=null;function te(){let I=h.topY+2.1,k=new gt(Math.max(.3,h.mouthR+.25),mn.clamp(h.R*2.4,1.5,3.2),I,40,1,!0);P?(P.geometry.dispose(),P.geometry=k):(P=new Le(k,F),P.frustumCulled=!1,w.add(P)),P.position.y=I/2+.05,P.visible=u.beamInt>0}function j(){let I=_(u.beamColor);F=new Dt({transparent:!0,depthWrite:!1,blending:Xn,side:It,uniforms:{uInt:{value:u.beamInt},uColor:{value:new E(I[0],I[1],I[2])}},vertexShader:mh,fragmentShader:gh})}j();let q=null,he=null;function Se(){let k=new Float32Array(330),Y=new Float32Array(110),fe=new Float32Array(110);for(let xe=0;xe<110;xe++){let Fe=Math.sqrt(a())*2,nt=a()*Math.PI*2;k[xe*3]=Math.cos(nt)*Fe,k[xe*3+1]=a()*4.6,k[xe*3+2]=Math.sin(nt)*Fe,Y[xe]=a(),fe[xe]=.02+a()*.035}let ge=new mt;ge.setAttribute("position",new pt(k,3)),ge.setAttribute("aSeed",new pt(Y,1)),ge.setAttribute("aSize",new pt(fe,1));let ce=_(u.dustColor);q=new Dt({transparent:!0,depthWrite:!1,blending:Xn,uniforms:{uTime:{value:0},uScale:{value:600},uColor:{value:new E(ce[0],ce[1],ce[2])}},vertexShader:`
        attribute float aSeed; attribute float aSize;
        uniform float uTime; uniform float uScale;
        varying float vA;
        void main() {
          vec3 p = position;
          p.y = mod(p.y - uTime * (0.05 + aSeed * 0.1), 4.6);
          p.x += sin(uTime * 0.25 + aSeed * 40.0) * 0.1;
          float hFade = smoothstep(0.0, 0.5, p.y) * (1.0 - smoothstep(3.6, 4.6, p.y));
          float rFade = 1.0 - smoothstep(1.1, 2.1, length(p.xz));
          vA = (0.22 + aSeed * 0.3) * hFade * rFade;
          vec4 mv = modelViewMatrix * vec4(p, 1.0);
          gl_PointSize = aSize * uScale / max(0.1, -mv.z);
          gl_Position = projectionMatrix * mv;
        }`,fragmentShader:`
        varying float vA; uniform vec3 uColor;
        void main() {
          float r = length(gl_PointCoord * 2.0 - 1.0);
          gl_FragColor = vec4(uColor, vA * pow(max(0.0, 1.0 - r), 2.0));
        }`}),he=new Yi(ge,q),he.frustumCulled=!1,w.add(he)}r||Se();let{BUCKETS:ue,billGeo:Re}=Yd(Qi);function De(){let I=[],k=new an,Y=new kt,fe=new kt,ge=new kt;ge.setFromEuler(new an(-Math.PI/2,0,0));let ce=Rt(9e3+[...h.key].reduce((Pt,_t)=>Pt+_t.charCodeAt(0),0)+(d?7:0)),xe=d&&h.rIn(h.fillBottom+.05)>.32?Qi.billRatio:0,Fe=Qi.coinR,nt=h.fillBottom;for(;nt<=h.fillTop;){let Pt=h.rIn(nt),_t=Math.max(.02,Pt-.02-Fe),un=Pt/Fe,Ln=h.stage?.35:mn.clamp((un-2.2)*.2,.03,.24),Ni=[];if(h.stage){let en=Math.max(3,Math.floor(_t*_t/(Fe*Fe)*h.density)),Jt=ce()*Math.PI*2;for(let Dn=0;Dn<en;Dn++)Ni.push({rad:_t*Math.sqrt((Dn+.5)/en)*(.94+ce()*.1),th:Dn*2.399963+Jt+(ce()-.5)*.6})}else{let en=[];for(let Jt=_t;Jt>Fe*.55;Jt-=Fe*2.02)en.push(Jt);(!en.length||en[en.length-1]>=Fe*2)&&en.push(0),en.reverse();for(let Jt of en){let Dn=Jt<Fe*1.02?1:Math.max(1,Math.floor(Math.PI/Math.asin(Math.min(1,Fe/Jt)))),Fi=ce()*Math.PI*2;for(let zn=0;zn<Dn;zn++)Ni.push({rad:Math.min(_t,Jt*(1+(ce()-.5)*.05)),th:Fi+(zn+(ce()-.5)*.14)/Dn*Math.PI*2})}}for(let en of Ni){let Jt=en.rad,Dn=en.th,Fi=new kt,zn=ce()<xe;zn&&(Jt=Math.min(Jt,Math.max(.03,h.rIn(nt)-.04-.27)));let or=h.stage?.03:h.coinH,cp=new E(Math.cos(Dn)*Jt,nt+(ce()-.5)*or,Math.sin(Dn)*Jt);zn?(Y.setFromEuler(k.set(0,ce()*Math.PI*2,0)),fe.setFromEuler(k.set((ce()-.5)*.5,0,(ce()-.5)*.5)),Fi.multiplyQuaternions(Y,fe).multiply(ge)):Fi.setFromEuler(k.set((ce()-.5)*2*Ln,ce()*Math.PI*2,(ce()-.5)*2*Ln));let ys;if(zn){let Fr=ce();ys=Fr<.35?3:Fr<.65?4:Fr<.85?5:6}else{let Fr=ce();ys=Fr<.2?1:Fr<.75?0:2}let Ta=ue[ys];I.push({kind:Ta.kind,bucket:ys,pos:cp,quat:Fi,tint:Math.floor(ce()*Ta.tints.length),s:zn?.93+ce()*.14:Ta.scale[0]+ce()*(Ta.scale[1]-Ta.scale[0]),slot:0})}let ba=h.stage?1:(1.16+Ln)/1.42;nt+=h.layerStep*ba*(.94+ce()*.12)}let vt=[];if(h.kind==="jar"&&h.mouthR>.17){let Pt=Math.min(h.topY-.1,h.fillTop+.16);for(let _t=I.length-1;_t>=Math.floor(I.length*.86)&&vt.length<6;_t--){let un=I[_t];if(un.kind!=="bill")continue;vt.push(_t);let Ln=ce()*Math.PI*2,Ni=ce()*Math.min(.14,h.mouthR*.35);un.pos.set(Math.cos(Ln)*Ni,Pt+ce()*.16,Math.sin(Ln)*Ni),Y.setFromEuler(k.set(0,ce()*Math.PI*2,0)),fe.setFromEuler(k.set((ce()-.5)*.35,0,Math.PI/2+(ce()-.5)*.3)),un.quat.copy(Y).multiply(fe)}}if(h.target&&!xe){let Pt=0;for(let _t of I)Pt+=ue[_t.bucket].value;for(;I.length>1&&Pt-ue[I[I.length-1].bucket].value>=h.target;)Pt-=ue[I.pop().bucket].value;for(let _t=I.length-1;_t>=0&&Pt-h.target>=.5;_t--){let un=I[_t];if(un.kind!=="coin")continue;let Ln=ue[un.bucket].value;Ln===2&&Pt-h.target>=1.5?(un.bucket=0,Pt-=1.5):Ln===.5&&(un.bucket=1,Pt-=.45)}}let Lt=I.length,wt=0;for(let Pt of I)wt+=ue[Pt.bucket].value;let In=(h.kind==="bucket"?h.rBot:h.R)+Fe+.06,Nr=Math.max(u.spillR?u.spillR(h):h.R+.34,In+.23),Ma=-.02+h.coinH*.5+.004,Sa=Ma+Math.max(.28,Math.min(.9,h.topY*.3)),_s=Ma,Lh=0;for(;Lh<wt&&_s<Sa;){let Pt=Math.max(In+.09,Nr-(_s-Ma)*.7),_t=.05+Math.min(.1,(Pt-In)*.1);for(let un=In;un<=Pt+.001;un+=Fe*2.02){let Ln=Math.max(1,Math.floor(Math.PI/Math.asin(Math.min(1,Fe/Math.max(un,Fe*1.02))))),Ni=ce()*Math.PI*2;for(let ba=0;ba<Ln;ba++){let en=Ni+(ba+(ce()-.5)*.14)/Ln*Math.PI*2,Jt=un+(ce()-.5)*.02,Dn=new kt().setFromEuler(k.set((ce()-.5)*2*_t,ce()*Math.PI*2,(ce()-.5)*2*_t)),Fi=ce(),zn=Fi<.2?1:Fi<.75?0:2,or=ue[zn];I.push({kind:"coin",bucket:zn,out:!0,pos:new E(Math.cos(en)*Jt,_s+(ce()-.5)*h.coinH*.6,Math.sin(en)*Jt),quat:Dn,tint:Math.floor(ce()*or.tints.length),s:or.scale[0]+ce()*(or.scale[1]-or.scale[0]),slot:0}),Lh+=or.value}}_s+=h.layerStep*.86*(.94+ce()*.12)}let xl=ue.map(()=>0),Dh=ue.map(()=>[0]);for(let Pt of I){Pt.slot=xl[Pt.bucket]++;for(let _t=0;_t<ue.length;_t++)Dh[_t].push(xl[_t])}return{items:I,bucketCounts:xl,prefs:Dh,poked:vt,nIn:Lt}}let Te={items:[],bucketCounts:[],prefs:[],poked:[],nIn:0},Ue=[],We=[],it=null;function Ee(){for(let Y of We){w.remove(Y);let fe=Array.isArray(Y.material)?Y.material:[Y.material];for(let ge of fe)ge.dispose();Y.dispose()}it&&it.dispose(),it=new gt(Qi.coinR,Qi.coinR,h.coinH,16),Te=De(),Ue=Te.items,We=ue.map((Y,fe)=>{let ge=Math.max(1,Te.bucketCounts[fe]),ce;if(Y.kind==="coin"){let xe=new st({map:Y.map,metalness:.82,roughness:.34,envMapIntensity:1.25}),Fe=new st({color:Y.side,metalness:.85,roughness:.36,envMapIntensity:1.2});ce=new ai(it,[Fe,xe,xe],ge)}else ce=new ai(Re,new st({map:Y.map,metalness:0,roughness:.8,side:It,envMapIntensity:.4}),ge);return ce.instanceMatrix.setUsage(jc),ce.frustumCulled=!1,w.add(ce),ce});let I=new Ve,k=new qe;for(let Y of Ue){let fe=We[Y.bucket];I.setHex(ue[Y.bucket].tints[Y.tint]),fe.setColorAt(Y.slot,I),k.compose(Y.pos,Y.quat,new E(Y.s,Y.s,Y.s)),fe.setMatrixAt(Y.slot,k)}for(let Y of We)Y.instanceColor&&(Y.instanceColor.needsUpdate=!0),Y.count=0}let ke=96,Xe=new mt,Tt=new Float32Array(ke*3),Ce=new Float32Array(ke),ot=new Float32Array(ke);Xe.setAttribute("position",new pt(Tt,3)),Xe.setAttribute("aLife",new pt(Ce,1)),Xe.setAttribute("aSize",new pt(ot,1));let Ke=new Dt({transparent:!0,depthWrite:!1,blending:Xn,uniforms:{uScale:{value:600}},vertexShader:`
      attribute float aLife; attribute float aSize;
      uniform float uScale; varying float vLife;
      void main() {
        vLife = aLife;
        vec4 mv = modelViewMatrix * vec4(position, 1.0);
        float s = aSize * (1.7 - aLife * 0.7) * step(0.001, aLife);
        gl_PointSize = s * uScale / max(0.1, -mv.z);
        gl_Position = projectionMatrix * mv;
      }`,fragmentShader:`
      varying float vLife;
      void main() {
        vec2 p = gl_PointCoord * 2.0 - 1.0;
        float r = length(p);
        float star = max(0.0, 1.0 - abs(p.x * p.y) * 6.0);
        float a = vLife * (pow(max(0.0, 1.0 - r), 1.6) + pow(star, 4.0) * 0.6);
        gl_FragColor = vec4(1.0, 0.88, 0.55, a);
      }`}),Ut=new Yi(Xe,Ke);Ut.frustumCulled=!1,w.add(Ut);let Et=0,N=0;function ut(I,k){let Y=Et;Et=(Et+1)%ke,Tt[Y*3]=I.x,Tt[Y*3+1]=I.y+.05,Tt[Y*3+2]=I.z,Ce[Y]=1,ot[Y]=k!==void 0?k:.06+a()*.06,N++,Xe.attributes.position.needsUpdate=!0}function Ct(I){if(N){N=0;for(let k=0;k<ke;k++)Ce[k]>0&&(Ce[k]=Math.max(0,Ce[k]-I*2.6),Ce[k]>0&&N++);Xe.attributes.aLife.needsUpdate=!0}}let lt=10,Mt=new mt,cn=new Float32Array(lt*3),Ot=new Float32Array(lt),An=new Float32Array(lt),mi=new Float32Array(lt);Mt.setAttribute("position",new pt(cn,3)),Mt.setAttribute("aLife",new pt(Ot,1)),Mt.setAttribute("aSize",new pt(An,1)),Mt.setAttribute("aRot",new pt(mi,1));let Rn=new Dt({transparent:!0,depthWrite:!1,blending:Xn,uniforms:{uScale:{value:600}},vertexShader:`
      attribute float aLife; attribute float aSize; attribute float aRot;
      uniform float uScale; varying float vLife; varying float vRot;
      void main() {
        vLife = aLife; vRot = aRot;
        vec4 mv = modelViewMatrix * vec4(position, 1.0);
        float k = 1.0 - aLife;
        float pop = sin(3.14159 * min(1.0, k * 1.15)); // quick bloom, soft fade
        gl_PointSize = aSize * (0.35 + pop) * uScale / max(0.1, -mv.z) * step(0.001, aLife);
        gl_Position = projectionMatrix * mv;
      }`,fragmentShader:`
      varying float vLife; varying float vRot;
      void main() {
        float c = cos(vRot), s = sin(vRot);
        vec2 p = gl_PointCoord * 2.0 - 1.0;
        p = mat2(c, -s, s, c) * p;
        float r = length(p);
        // 4 long rays on the rotated axes + 4 short diagonals + a hot core;
        // the ray term fades with radius so the cross tapers like a real glint
        float rays = max(0.0, 1.0 - abs(p.x * p.y) * 7.0) * max(0.0, 1.0 - r * 0.8);
        vec2 d = mat2(0.7071, -0.7071, 0.7071, 0.7071) * p;
        float diag = max(0.0, 1.0 - abs(d.x * d.y) * 26.0) * max(0.0, 1.0 - r * 1.15);
        float core = pow(max(0.0, 1.0 - r * 1.6), 2.2);
        float k = 1.0 - vLife;
        float glow = sin(3.14159 * min(1.0, k * 1.15));
        float a = glow * (pow(rays, 4.0) + pow(diag, 5.0) * 0.4 + core);
        vec3 col = vec3(1.35, 1.18, 0.85) * (0.7 + 0.6 * glow); // >1 \u2192 blooms
        gl_FragColor = vec4(col, a);
      }`}),gi=new Yi(Mt,Rn);gi.frustumCulled=!1,w.add(gi);let vi=0,qt=0,Jn=new E;function er(I,k){let Y=vi;vi=(vi+1)%lt,Jn.copy(R.position).sub(I).normalize().multiplyScalar(.09),cn[Y*3]=I.x+Jn.x,cn[Y*3+1]=I.y+.03+Jn.y,cn[Y*3+2]=I.z+Jn.z,Ot[Y]=1,An[Y]=k!==void 0?k:.26+a()*.2,mi[Y]=a()*Math.PI,qt++,Mt.attributes.position.needsUpdate=!0,Mt.attributes.aRot.needsUpdate=!0,Mt.attributes.aSize.needsUpdate=!0}function Rr(I){if(qt){qt=0;for(let k=0;k<lt;k++)Ot[k]>0&&(Ot[k]=Math.max(0,Ot[k]-I*1.15),Ot[k]>0&&qt++);Mt.attributes.aLife.needsUpdate=!0}}let Yt=160,xn=new mt,gn=new Float32Array(Yt*3),Cn=new Float32Array(Yt),C=new Float32Array(Yt),W=new Float32Array(Yt*3),oe=new Float32Array(Yt*3);xn.setAttribute("position",new pt(gn,3)),xn.setAttribute("aLife",new pt(Cn,1)),xn.setAttribute("aSize",new pt(C,1)),xn.setAttribute("aCol",new pt(W,3));let Z=new Dt({transparent:!0,depthWrite:!1,blending:_r,uniforms:{uScale:{value:600}},vertexShader:`
      attribute float aLife; attribute float aSize; attribute vec3 aCol;
      uniform float uScale;
      varying float vLife; varying vec3 vCol;
      void main() {
        vLife = aLife; vCol = aCol;
        vec4 mv = modelViewMatrix * vec4(position, 1.0);
        gl_PointSize = aSize * uScale * step(0.001, aLife) / max(0.1, -mv.z);
        gl_Position = projectionMatrix * mv;
      }`,fragmentShader:`
      varying float vLife; varying vec3 vCol;
      void main() {
        float r = length(gl_PointCoord * 2.0 - 1.0);
        float a = smoothstep(1.0, 0.72, r) * min(1.0, vLife * 2.2);
        gl_FragColor = vec4(vCol, a);
      }`}),x=new Yi(xn,Z);x.frustumCulled=!1,w.add(x);let O=0,$=0;function ie(I,k=1){for(let Y=0;Y<I;Y++){let fe=$;$=($+1)%Yt,gn[fe*3]=(a()-.5)*.6,gn[fe*3+1]=h.topY+.15+a()*.2,gn[fe*3+2]=(a()-.5)*.6,oe[fe*3]=(a()-.5)*3.6,oe[fe*3+1]=2+a()*2.6,oe[fe*3+2]=(a()-.5)*3.6,Cn[fe]=1,C[fe]=(.1+a()*.12)*k;let ge=o[Y%o.length];W[fe*3]=ge[0],W[fe*3+1]=ge[1],W[fe*3+2]=ge[2]}O=Math.min(Yt,O+I),xn.attributes.aCol.needsUpdate=!0}function L(I){if(!O)return;O=0;let k=1-1.1*I;for(let Y=0;Y<Yt;Y++)Cn[Y]<=0||(Cn[Y]=Math.max(0,Cn[Y]-I*.22),Cn[Y]>0&&O++,oe[Y*3+1]-=2.4*I,oe[Y*3]*=k,oe[Y*3+1]*=k,oe[Y*3+2]*=k,gn[Y*3]+=oe[Y*3]*I+Math.sin((1-Cn[Y])*9+Y)*I*.35,gn[Y*3+1]+=oe[Y*3+1]*I,gn[Y*3+2]+=oe[Y*3+2]*I);xn.attributes.position.needsUpdate=!0,xn.attributes.aLife.needsUpdate=!0}let z=0,de=0,ve=0,ye=.03,_e=[],we=[],Me=new Set,ze=new qe,ct=new E,et=new E,He=new kt;function je(I,k,Y,fe,ge,ce){ct.set(k,Y,fe),et.setScalar(Math.max(1e-4,ce)),ze.compose(ct,ge,et),We[I.bucket].setMatrixAt(I.slot,ze)}function $e(I){let k=Ue[I];je(k,k.pos.x,k.pos.y,k.pos.z,k.quat,k.s)}function ft(){for(let I=0;I<We.length;I++)We[I].count=Te.prefs[I][z]}function Bt(){return new kt().setFromEuler(new an(a()*Math.PI*2,a()*Math.PI*2,a()*Math.PI*2))}let Je=0;function Ze(I){let k=Ue[I],Y;if(k.out){let ce=Math.atan2(k.pos.z,k.pos.x)+(a()-.5)*.5,xe=h.R+.24+a()*.15;Y=new E(Math.cos(ce)*xe,h.topY+.25+a()*.35,Math.sin(ce)*xe)}else{let ce=Math.max(.03,h.mouthR*.42),xe=Je*2.39996,Fe=Math.sqrt((Je%9+.5)/9)*ce;Je++,Y=new E(Math.cos(xe)*Fe,h.topY+.2+a()*.32,Math.sin(xe)*Fe)}let fe=Math.sqrt(2*Math.max(.15,Y.y-k.pos.y)/Qi.gravity),ge=new E(a()-.5,a()-.5,a()-.5).normalize();_e.push({i:I,t:0,dur:fe,from:Y,q0:Bt(),axis:ge,w:4+a()*7,sparked:!1}),je(k,Y.x,Y.y,Y.z,He.copy(k.quat),k.s*.9)}function $t(I){I=mn.clamp(I,0,200);let k=Te.nIn,Y=Ue.length-k;return I<=100||!Y?Math.round(k*Math.min(I,100)/100):k+Math.round(Y*(I-100)/100)}function tr(I){let k=Te.nIn,Y=Ue.length-k;return I<=k||!Y?k?I/k*100:0:100+(I-k)/Y*100}function Cr(){m++;let I=(m-1)%Ie;ne(I);let k=Be();le.add(k),u.archPedestal&&le.add(Oe(Ne(I))),re={jar:k,from:new E(0,0,0),to:Ne(I),t:0,dur:r?.001:1.35},de=0,z=0,_e.length=0,we.length=0,Me.clear(),ve=0,ft();for(let Y of We)Y.instanceMatrix.needsUpdate=!0;if(Ur.clear(),xa=!1,Dr=!1,c.blip(),t({type:"event",kind:"rolloverDone",jarPct:0}),g=Math.max(0,g-1),g>0)gs(200);else if(f>=0){let Y=f;f=-1,Mn($t(Y))}}function Mn(I){de=Math.max(0,Math.min(Ue.length,I));for(let k=we.length-1;k>=0;k--)we[k].i<de&&($e(we[k].i),we.splice(k,1));for(let k of Array.from(Me))k<de&&(Me.delete(k),$e(k));for(let k of We)k.instanceMatrix.needsUpdate=!0;if(de>z){let k=de-z,Y=mn.clamp(2.2+(h.liters||2)*.55,4.4,9),fe=mn.clamp(.4+k*.028,.7,Y);ye=Math.max(.0015,fe/k),ve=ye}else if(de<z){let k=new Set(_e.map(ce=>ce.i)),Y=new Set(we.map(ce=>ce.i)),fe=Math.min(.022,1.4/Math.max(1,z-de)),ge=0;for(let ce=z-1;ce>=de;ce--)k.has(ce)||Y.has(ce)||Me.has(ce)||(we.push({i:ce,t:-ge}),ge+=fe)}}let hn=I=>I<=0?0:I>=1?1:I*I*(3-2*I),Li=.26;function Bn(I){let k=!1;if(z<de){for(ve+=I;ve>=ye&&z<de;)ve-=ye,Ze(z++);ft(),k=!0}else ve=0;for(let fe=_e.length-1;fe>=0;fe--){let ge=_e[fe],ce=Ue[ge.i];if(ge.t+=I,k=!0,ge.t<ge.dur){let xe=ge.t/ge.dur,Fe=Math.max(ce.pos.y,ge.from.y-.5*Qi.gravity*ge.t*ge.t),nt=hn(Math.min(1,xe/.85)),vt=ge.from.x+(ce.pos.x-ge.from.x)*nt,Lt=ge.from.z+(ce.pos.z-ge.from.z)*nt;if(!ce.out){let wt=ce.kind==="coin"?.115:.27,$n=Math.hypot(vt,Lt),In=Math.max(.02,h.rIn(Fe)-.03-wt);if($n>In){let Nr=In/$n;vt*=Nr,Lt*=Nr}}He.setFromAxisAngle(ge.axis,ge.w*ge.t).premultiply(ge.q0),He.slerp(ce.quat,hn((xe-.5)/.45)),je(ce,vt,Fe,Lt,He,ce.s)}else{ge.sparked||(ge.sparked=!0,ut(ce.pos),c.clink());let xe=ge.t-ge.dur;if(xe<Li){let Fe=ce.pos.y+.04*Math.exp(-xe*10)*Math.abs(Math.sin(xe*24));je(ce,ce.pos.x,Fe,ce.pos.z,ce.quat,ce.s)}else $e(ge.i),_e.splice(fe,1),ge.i>=de&&we.push({i:ge.i,t:0})}}for(let fe=we.length-1;fe>=0;fe--){let ge=we[fe];if(ge.t+=I,ge.t<0)continue;k=!0;let ce=Ue[ge.i],xe=Math.min(1,ge.t/.38),Fe=ce.pos.y+xe*xe*(h.topY*.3+.35),nt=ce.pos.x,vt=ce.pos.z;if(!ce.out){let Lt=(ce.kind==="coin"?.115:.27)*(1-xe),wt=Math.hypot(nt,vt),$n=Math.max(.02,h.rIn(Math.min(h.topY-.05,Fe))-.02-Lt);if(wt>$n){let In=$n/wt;nt*=In,vt*=In}}je(ce,nt,Fe,vt,ce.quat,ce.s*(1-xe)),xe>=1&&(we.splice(fe,1),Me.add(ge.i))}let Y=!1;for(;z>0&&Me.has(z-1);)Me.delete(z-1),z--,Y=!0;if(Y&&(ft(),k=!0),k)for(let fe of We)fe.instanceMatrix.needsUpdate=!0;return k}let Pr=0,Kn=1.22,Di=1,nr=8,_a=-10,tt=1,kn=new Map,Zt=0,vn=S.domElement;vn.addEventListener("pointerdown",I=>{if(vn.setPointerCapture(I.pointerId),kn.set(I.pointerId,{x:I.clientX,y:I.clientY}),kn.size===2){let[k,Y]=[...kn.values()];Zt=Math.hypot(k.x-Y.x,k.y-Y.y)}c.unlock()}),vn.addEventListener("pointermove",I=>{let k=kn.get(I.pointerId);if(k&&(_a=bt,kn.size===1&&(Pr-=(I.clientX-k.x)*.005,Kn=mn.clamp(Kn-(I.clientY-k.y)*.004,.92,1.42)),k.x=I.clientX,k.y=I.clientY,kn.size===2)){let[Y,fe]=[...kn.values()],ge=Math.hypot(Y.x-fe.x,Y.y-fe.y);Zt>0&&(Di=mn.clamp(Di*Zt/ge,.5,1.5)),Zt=ge}});let ya=I=>{kn.delete(I.pointerId),Zt=0};vn.addEventListener("pointerup",ya),vn.addEventListener("pointercancel",ya),vn.addEventListener("wheel",I=>{I.preventDefault(),_a=bt,Di=mn.clamp(Di*(1+I.deltaY*.0012),.5,1.5)},{passive:!1});function ir(I){let k=I-_a>3&&kn.size===0;tt+=((k&&!r?1:0)-tt)*.02;let Y=r?1:hn(Math.min(1,I/1.7)),fe=Pr-.7*(1-Y)+Math.sin(I*.3)*.055*tt,ge=Kn+Math.sin(I*.21)*.012*tt,ce=nr*Di*(1+.45*(1-Y));R.position.set(B.x+ce*Math.sin(ge)*Math.sin(fe),B.y+ce*Math.cos(ge),B.z+ce*Math.sin(ge)*Math.cos(fe)),R.lookAt(B),se.position.set(Math.sin(fe+.55)*4,5.5,Math.cos(fe+.55)*4),X.position.set(Math.sin(fe+Math.PI-.5)*4,3.5,Math.cos(fe+Math.PI-.5)*4)}function Ir(I){return I==="high"?!0:I==="low"?!1:(devicePixelRatio||1)>=1.5&&(navigator.hardwareConcurrency||4)>=4}let St=n.quality||"auto",Sn=Ir(St),Lr=Zd(S);function Pn(){if(!Sn){S.setRenderTarget(null),S.render(w,R);return}Lr.render(w,R)}function Qt(){let I=e.clientWidth,k=e.clientHeight;if(!I||!k)return;S.setSize(I,k),R.aspect=I/k,R.fov=I<k*.75?42:36,R.updateProjectionMatrix();let Y=k*S.getPixelRatio()*.5/Math.tan(R.fov*Math.PI/360);Ke.uniforms.uScale.value=Y,Rn.uniforms.uScale.value=Y,Z.uniforms.uScale.value=Y,q&&(q.uniforms.uScale.value=Y);let fe=p.top+6,ge=p.bottom+24,ce=Math.max(.3,(k-fe-ge)/k),xe=Math.min(14,h.camSpan/ce);nr=xe/(2*Math.tan(R.fov*Math.PI/360));let Fe=(fe+(k-fe-ge)/2)/k;B.y=h.centerY+(Fe-.5)*xe;let nt=h.R*2.1+.4,vt=Math.tan(R.fov*Math.PI/360)*R.aspect*nr;vt<nt&&(nr*=nt/vt);let Lt=p.right||0,wt=p.left||0,$n=(wt+(I-wt-Lt)/2)/I;R.projectionMatrix.elements[8]=2*(.5-$n),Lr.resize()}addEventListener("resize",Qt);let bt=0,rr=performance.now(),ar=1/60,sr=!1,vl=0,Eh=.5,_n=null,_l=0,wh=6,xa=!1,Dr=!1,Ui=-1,Ah=[25,50,75,125,150,175],Ur=new Set,Rh=new an;function np(){let I=0;for(let k of we)k.t>=0&&I++;return Math.max(0,z-_e.length-I-Me.size)}let Ch=()=>{let I=performance.now(),k=Math.min(.05,(I-rr)/1e3);rr=I,bt+=k,Bn(k),Ct(k),Rr(k),L(k),q&&(q.uniforms.uTime.value=bt);let Y=np(),fe=tr(Y),ge=Math.max(0,Math.min(1,(fe-75)/25));if(F.uniforms.uInt.value=u.beamInt+ge*.08,vl+=k,vl>Eh&&!r&&(vl=0,Eh=(.25+a()*.6)*(1-.62*ge),Y>8)){let xe=Y-Te.nIn,Fe=xe>5&&a()<.35?Te.nIn+Math.floor(a()*xe):Math.floor(a()*Y);a()<.6?er(Ue[Fe].pos):ut(Ue[Fe].pos,.045+a()*.05)}if(!r)for(let xe of Te.poked){if(xe>=z||Me.has(xe))continue;let Fe=!1;for(let vt of _e)if(vt.i===xe){Fe=!0;break}if(!Fe){for(let vt of we)if(vt.i===xe){Fe=!0;break}}if(Fe)continue;let nt=Ue[xe];He.setFromEuler(Rh.set(Math.sin(bt*1.1+xe)*.05,0,Math.sin(bt*.8+xe*2.1)*.06)),He.multiply(nt.quat),je(nt,nt.pos.x,nt.pos.y,nt.pos.z,He,nt.s),We[nt.bucket].instanceMatrix.needsUpdate=!0}let ce=_e.length===0&&we.length===0;if(!r&&ce&&Y>Te.nIn+8&&(_l+=k,!_n&&_l>wh)){_l=0,wh=3+a()*5;let xe=Y-Te.nIn;_n={i:Te.nIn+Math.min(xe-1,Math.floor(xe*(.55+a()*.45))),t:0,dur:.5,ax:a()-.5,az:a()-.5}}if(_n){let xe=Ue[_n.i];if(!ce||_n.i>=Math.min(de,z))$e(_n.i),We[xe.bucket].instanceMatrix.needsUpdate=!0,_n=null;else{_n.t+=k;let Fe=Math.min(1,_n.t/_n.dur),nt=Math.sin(Math.PI*Fe);He.setFromEuler(Rh.set(_n.ax*.34*nt,0,_n.az*.34*nt)),He.multiply(xe.quat),je(xe,xe.pos.x,xe.pos.y+nt*.016,xe.pos.z,He,xe.s),We[xe.bucket].instanceMatrix.needsUpdate=!0,Fe>=1&&($e(_n.i),er(xe.pos,.24),a()<.4&&c.clink(),_n=null)}}for(let xe of Ah)fe>=xe&&fe<(xe<100?99.9:199.9)&&!Ur.has(xe)?(Ur.add(xe),r||ie(45,.7),c.blip(),t({type:"event",kind:"milestone",jarPct:xe/100})):fe<xe-8&&Ur.delete(xe);if(Y>=Te.nIn&&Te.nIn>0&&!xa?(xa=!0,r||ie(Yt),c.chime(),t({type:"event",kind:"goalReached",jarPct:1})):Y<Te.nIn*.95&&(xa=!1),Y===Ue.length&&Ue.length>Te.nIn&&g>0&&!Dr?(Dr=!0,r||ie(Yt),c.chime(),t({type:"event",kind:"zoneFull",jarPct:2}),Ui=bt+(r?1:2.3)):fe<190&&(Dr=!1,g===0&&(Ui=-1)),Ui>0&&bt>=Ui&&(Ui=-1,Cr()),re){re.t+=k;let xe=Math.min(1,re.t/re.dur),Fe=hn(xe);re.jar.position.lerpVectors(re.from,re.to,Fe),re.jar.position.y+=Math.sin(Math.PI*Fe)*(1.1+h.topY*.18),re.jar.rotation.y=Fe*2.2,xe>=1&&(ut(ct.set(re.to.x,re.to.y+h.topY*.7,re.to.z),.09),re=null,c.clink(),ne())}ir(bt),Pn(),ar+=(k-ar)*.05,!sr&&bt>5&&ar>.028&&(sr=!0,Sn=!1,S.setPixelRatio(1),Qt(),t({type:"perf",fps:Math.round(1/ar),quality:"degraded"}))};function gs(I){I=mn.clamp(Math.round(I||0),0,200),de=$t(I),z=de,ft();for(let k of We)k.instanceMatrix.needsUpdate=!0;xa=de>=Te.nIn&&de>0,Dr=de===Ue.length&&Ue.length>Te.nIn,Ui=Dr&&g>0?bt+2.5:-1,Ur.clear();for(let k of Ah)I>=k&&Ur.add(k)}function Ph(){if(g>0){m+=g,g=0;let I=f>=0?f:0;return f=-1,Ui=-1,I}return null}function Ih(){return Ue.length?Math.round(tr(de)):0}function yl(I,k={}){let Y=pl.find(ce=>ce.key===I);if(!Y)return;let fe=Ph(),ge=k.pct!==void 0?k.pct:fe!==null?fe:Ih();if(l=Y,h=xh(Y),_e.length=0,we.length=0,Me.clear(),z=0,de=0,ve=0,me(),A(),te(),he){let ce=Math.max(.5,h.R/.84);he.scale.set(ce,Math.max(.45,(h.topY+1.3)/4.8),ce)}Ee(),Qt(),gs(ge)}function ip(I){let k=dl.find(ge=>ge.key===I);if(!k)return;let Y=Ph(),fe=Y!==null?Y:Ih();u=k,_e.length=0,we.length=0,Me.clear(),z=0,de=0,ve=0,me(),A(),Ee(),ee(),gs(fe)}let vs=!1;function rp(I){c.tada(),r||ie((+I.deltaPct||0)>=.1?70:30,.7);let k=mn.clamp(+I.jarPctAfter||0,0,2)*100,Y=Math.max(0,Math.floor(I.rollovers||0));Y>0?(g+=Y,f=k,Mn(Ue.length)):g>0?f=k:Mn($t(k))}function ap(I,k){g=0,f=-1,Ui=-1,m=Math.max(0,Math.floor(I.bankedJars||0)),ne();let Y=mn.clamp(+I.jarPct||0,0,2)*100;k?gs(Y):Mn($t(Y))}function sp(I){if(I.insets&&(p={top:0,bottom:0,...I.insets},Qt()),I.theme!==void 0){let k=$i.find(Y=>Y.key===I.theme);k&&v(k)}I.sound!==void 0&&c.setCoins(!!I.sound),I.tipSound!==void 0&&c.setFanfare(!!I.tipSound),I.quality!==void 0&&(St=I.quality,Sn=sr?!1:Ir(St)),I.notes!==void 0&&!!I.notes!==d&&(d=!!I.notes,yl(l.key)),I.vessel!==void 0&&I.vessel!==l.key&&yl(I.vessel),I.scene!==void 0&&I.scene!==u.key&&ip(I.scene)}function op(I){I=!!I,I!==vs&&(vs=I,vs?S.setAnimationLoop(null):(rr=performance.now(),S.setAnimationLoop(Ch)))}let lp=mn.clamp(i.state&&i.state.jarPct||0,0,2)*100;return yl(l.key,{pct:lp}),S.setAnimationLoop(Ch),i.ready(),{applyTip:rp,syncState:ap,setConfig:sp,setPaused:op,jarPct:()=>mn.clamp(tr(de)/100,0,2),perf:()=>({fps:vs?0:Math.round(1/ar),quality:sr?"degraded":Sn?"high":"low"})}}var Pe={jarW:.54,wall:.022,bodyTop:.78,shoulderEnd:.88,neckTop:.965,coinR:.036,fillTop:.82,billRatio:.12,edgeRatio:.08,gravity:20,dprMax:2},bh={copper:{base:"#c07a45",dark:"#8a4f24",lite:"#e6a670",ink:"rgba(74,40,14,0.8)"},gold:{base:"#d9a94e",dark:"#997026",lite:"#f2d183",ink:"rgba(90,62,16,0.8)"},silver:{base:"#cdd2d7",dark:"#868f98",lite:"#f0f3f6",ink:"rgba(62,70,78,0.8)"}},km=[{numeral:"5",ring:"copper",center:null,scale:.82},{numeral:"50",ring:"gold",center:null,scale:.94},{numeral:"1",ring:"gold",center:"silver",scale:.92},{numeral:"2",ring:"silver",center:"gold",scale:1}],zm=["copper","gold","silver"],Kd=[{n:"5",bg:"#bcc0c5",dk:"#565b61",band:"#dfe2e6"},{n:"10",bg:"#d89b94",dk:"#8a4a44",band:"#eecfcb"},{n:"20",bg:"#92aed6",dk:"#40608c",band:"#d3e0f0"},{n:"50",bg:"#e0a95e",dk:"#8f6222",band:"#f2ddb4"}];function $d(i){let{host:e,emit:t}=i,n=i.config||{},r=!!i.reduced,a=Rt(20260703),s=$i.find(C=>C.key===n.theme)||$i[0];ga(s);let o=ol();o.setCoins(!!n.sound),o.setFanfare(!!n.tipSound);let c=n.notes===void 0?!0:!!n.notes,l={top:0,bottom:0,...n.insets||{}},h=Math.max(0,Math.floor(i.state&&i.state.bankedJars||0)),u=[],d=0,p=-1,m=-1,g=Pe.jarW/2-Pe.wall,f=g*.66,v=.055;function _(C){let W=Pe.wall;if(C<W+v){let x=(W+v-C)/v;return g-v*(1-Math.sqrt(Math.max(0,1-x*x)))}if(C<=Pe.bodyTop)return g;if(C>=Pe.shoulderEnd)return f;let oe=(C-Pe.bodyTop)/(Pe.shoulderEnd-Pe.bodyTop),Z=oe*oe*(3-2*oe);return g+(f-g)*Z}function y(){let C=[],W=Pe.coinR,oe=c?Pe.billRatio:0,Z=Rt(20260703+(c?0:5)),x=Pe.wall+W*1.05,O=0;for(;x<Pe.fillTop;){let z=_(x+W*.4)-W*1.05,de=W*1.58,ve=Math.max(1,Math.floor(z*2/de)+1),ye=O%2*W*.8-W*.4;for(let _e=0;_e<ve;_e++){let Me=(_e%2===1?1:-1)*Math.ceil(_e/2)*de+ye+(Z()-.5)*W*.45;Me=Math.max(-z,Math.min(z,Me));let ze=x+(Z()-.5)*W*.35,ct=Z(),et=ct<oe?"bill":ct<oe+Pe.edgeRatio?"edge":"coin";if(et==="bill"){let je=Math.max(0,z-W*1.5);Me=Math.max(-je,Math.min(je,Me))}let He;if(et==="bill"){let je=Z();He=je<.35?0:je<.65?1:je<.85?2:3}else if(et==="edge"){let je=Z();He=je<.25?0:je<.7?1:2}else{let je=Z();He=je<.15?0:je<.45?1:je<.72?3:2}C.push({type:et,v:He,x:Me,y:ze,rot:et==="coin"?Z()*Math.PI*2:et==="edge"?(Z()-.5)*.7:(Z()-.5)*.55,s:.94+Z()*.12})}x+=W*1.28*(.95+Z()*.1),O++}if(c)for(let z=0;z<4;z++)C.push({type:"billup",x:(Z()-.5)*f*1.1,y:Pe.neckTop-.065+Z()*.04,rot:(Z()-.5)*.35,v:Math.floor(Z()*Kd.length),s:.95+Z()*.1});let $=C.length,ie=Pe.jarW/2+.012,L=.46;for(let z=0;z<12;z++){let de=Pe.coinR*.62+z*Pe.coinR*1.12,ve=ie+Pe.coinR*.7+(z>0?Pe.coinR*.12:0),ye=ie+L-z*Pe.coinR*1.5;if(ye-ve<Pe.coinR*1.2)break;let _e=Pe.coinR*1.55,we=Math.max(1,Math.floor((ye-ve)/_e));for(let Me=0;Me<we;Me++)for(let ze of[-1,1]){let ct=de+(Z()-.5)*Pe.coinR*.3,et=ve+Me*_e+(Z()-.5)*Pe.coinR*.4;if(c&&Z()<.22&&ye-ve>Pe.coinR*2.2){et=Math.max(ve+Pe.coinR*1.6,Math.min(ye-Pe.coinR*.4,et));let He=Z();C.push({type:"bill",out:!0,x:ze*et,y:ct,v:He<.35?0:He<.65?1:He<.85?2:3,rot:ze*(.06+Z()*.24),s:.94+Z()*.12})}else{let He=Z();C.push({type:"coin",out:!0,x:ze*et,y:ct,v:He<.15?0:He<.45?1:He<.72?3:2,rot:Z()*Math.PI*2,s:.94+Z()*.12})}}}return{items:C,nIn:$}}let S=y(),w=S.items;function R(C){C=Math.min(200,Math.max(0,C));let W=S.nIn,oe=w.length-W;return C<=100||!oe?Math.round(W*Math.min(C,100)/100):W+Math.round(oe*(C-100)/100)}function B(C){let W=S.nIn,oe=w.length-W;return C<=W||!oe?W?C/W*100:0:100+(C-W)/oe*100}let G=document.createElement("canvas");e.appendChild(G),G.addEventListener("pointerdown",()=>o.unlock());let D=G.getContext("2d"),J=document.createElement("canvas"),K=document.createElement("canvas"),V=document.createElement("canvas"),se=document.createElement("canvas"),X=0,ee=0,Q=1,me=0,ae=0,be=0,Be=null,Ie=null,Ne=null,le=C=>ae+C*me,re=C=>be-C*me,ne=C=>C*me;function Oe(C,W,oe,Z,x,O){C.beginPath(),C.moveTo(W+O,oe),C.arcTo(W+Z,oe,W+Z,oe+x,O),C.arcTo(W+Z,oe+x,W,oe+x,O),C.arcTo(W,oe+x,W,oe,O),C.arcTo(W,oe,W+Z,oe,O),C.closePath()}function Ge(C,W,oe){let Z=document.createElement("canvas");Z.width=Math.max(2,Math.ceil(C*Q)),Z.height=Math.max(2,Math.ceil(W*Q));let x=Z.getContext("2d");return x.scale(Q,Q),oe(x,C,W),{c:Z,w:C,h:W}}function T(){let C=ne(Pe.coinR),W=km.map(ie=>{let L=C*ie.scale;return Ge(L*2+4,L*2+4,(z,de,ve)=>{let ye=de/2,_e=ve/2,we=bh[ie.ring],Me=z.createRadialGradient(ye-L*.25,_e-L*.3,L*.1,ye,_e,L*1.02);Me.addColorStop(0,we.lite),Me.addColorStop(.38,we.base),Me.addColorStop(.85,we.base),Me.addColorStop(1,we.dark),z.fillStyle=Me,z.beginPath(),z.arc(ye,_e,L,0,7),z.fill(),z.strokeStyle=we.dark,z.globalAlpha=.55,z.lineWidth=Math.max(1,L*.06),z.beginPath(),z.arc(ye,_e,L*.95,0,7),z.stroke(),z.globalAlpha=1;let ze=we.ink;if(ie.center){let He=bh[ie.center];Me=z.createRadialGradient(ye-L*.14,_e-L*.18,L*.05,ye,_e,L*.6),Me.addColorStop(0,He.lite),Me.addColorStop(.4,He.base),Me.addColorStop(.85,He.base),Me.addColorStop(1,He.dark),z.fillStyle=Me,z.beginPath(),z.arc(ye,_e,L*.56,0,7),z.fill(),z.strokeStyle=He.dark,z.globalAlpha=.5,z.lineWidth=Math.max(1,L*.045),z.beginPath(),z.arc(ye,_e,L*.56,0,7),z.stroke(),z.globalAlpha=1,ze=He.ink}z.fillStyle=we.dark,z.globalAlpha=.45;for(let He=0;He<12;He++){let je=He/12*Math.PI*2;z.beginPath(),z.arc(ye+Math.cos(je)*L*.77,_e+Math.sin(je)*L*.77,L*.05,0,7),z.fill()}z.globalAlpha=1;let ct=L*(ie.numeral.length>1?.62:.88);z.font=`800 ${ct}px Georgia, serif`,z.textAlign="center",z.textBaseline="middle",z.fillStyle="rgba(255,255,255,0.4)",z.fillText(ie.numeral,ye+L*.03,_e+L*.085),z.fillStyle=ze,z.fillText(ie.numeral,ye,_e+L*.04);let et=z.createLinearGradient(ye-L,_e-L,ye+L*.6,_e+L*.6);et.addColorStop(0,"rgba(255,255,255,0.2)"),et.addColorStop(.45,"rgba(255,255,255,0)"),z.fillStyle=et,z.beginPath(),z.arc(ye,_e,L*.98,0,7),z.fill()})}),oe=zm.map(ie=>{let L=bh[ie];return Ge(C*2+4,C*.7+4,(z,de,ve)=>{let ye=C*1.9,_e=C*.34,we=(de-ye)/2,Me=(ve-_e)/2,ze=z.createLinearGradient(0,Me,0,Me+_e);ze.addColorStop(0,L.lite),ze.addColorStop(.45,L.base),ze.addColorStop(1,L.dark),z.fillStyle=ze,Oe(z,we,Me,ye,_e,_e*.35),z.fill(),z.strokeStyle="rgba(0,0,0,0.28)",z.lineWidth=Math.max(1,_e*.06),z.strokeRect(we+_e*.2,Me+_e*.18,ye-_e*.4,_e*.64)})}),Z=C*4.6,x=C*2.4,O=Kd.map(ie=>Ge(Z+4,x+4,L=>{L.fillStyle=ie.bg,Oe(L,2,2,Z,x,C*.16),L.fill(),L.fillStyle=ie.band,L.fillRect(2+Z*.6,2+x*.06,Z*.22,x*.88),L.strokeStyle=ie.dk,L.globalAlpha=.55,L.lineWidth=Math.max(1,C*.05),Oe(L,2+Z*.03,2+x*.06,Z*.94,x*.88,C*.12),L.stroke(),L.globalAlpha=.5,L.lineWidth=Math.max(1,C*.07),L.beginPath(),L.moveTo(2+Z*.16,2+x*.8),L.lineTo(2+Z*.16,2+x*.46),L.arc(2+Z*.27,2+x*.46,Z*.11,Math.PI,0),L.lineTo(2+Z*.38,2+x*.8),L.stroke(),L.globalAlpha=1,L.fillStyle=ie.dk,L.textAlign="center",L.textBaseline="middle",L.font=`900 ${Math.max(8,x*.4)}px Georgia, serif`,L.fillText(ie.n,2+Z*.88,2+x*.7),L.font=`900 ${Math.max(6,x*.2)}px Georgia, serif`,L.fillText(ie.n,2+Z*.1,2+x*.18),L.fillStyle="rgba(0,0,0,0.07)",L.beginPath(),L.moveTo(2+Z*.48,2),L.lineTo(2+Z*.55,2),L.lineTo(2+Z*.5,2+x),L.lineTo(2+Z*.44,2+x),L.closePath(),L.fill()})),$=Ge(C*3,C*3,(ie,L,z)=>{let de=ie.createRadialGradient(L/2,z/2,C*.2,L/2,z/2,C*1.45);de.addColorStop(0,"rgba(26,17,10,0.5)"),de.addColorStop(1,"rgba(26,17,10,0)"),ie.fillStyle=de,ie.fillRect(0,0,L,z)});return{coin:W,edge:oe,bill:O,halo:$}}function b(C){return C.type==="coin"?Ne.coin[C.v]:C.type==="edge"?Ne.edge[C.v]:Ne.bill[C.v]}function H(C,W,oe,Z,x,O,$,ie){let L=b(W);C.save(),C.globalAlpha=ie,C.translate(oe,Z),C.rotate(W.type==="billup"?x+Math.PI/2:x),C.scale(O*W.s,$*W.s),C.drawImage(L.c,-L.w/2,-L.h/2,L.w,L.h),C.restore()}function U(C){let W=new Path2D,oe=re(Pe.wall),Z=ne(v),x=C?0:re(Pe.neckTop);return W.moveTo(le(-f),x),W.lineTo(le(-f),re(Pe.shoulderEnd)),W.quadraticCurveTo(le(-g*.98),re((Pe.bodyTop+Pe.shoulderEnd)/2),le(-g),re(Pe.bodyTop)),W.lineTo(le(-g),oe-Z),W.quadraticCurveTo(le(-g),oe,le(-g)+Z,oe),W.lineTo(le(g)-Z,oe),W.quadraticCurveTo(le(g),oe,le(g),oe-Z),W.lineTo(le(g),re(Pe.bodyTop)),W.quadraticCurveTo(le(g*.98),re((Pe.bodyTop+Pe.shoulderEnd)/2),le(f),re(Pe.shoulderEnd)),W.lineTo(le(f),x),W.closePath(),W}function M(C){let W=ne(Pe.wall),oe=be,Z=ne(v+Pe.wall),x=ne(g)+W,O=ne(f)+W,$=ne(.012);C.beginPath(),C.moveTo(ae-O-$,re(1)),C.lineTo(ae-O,re(Pe.neckTop)),C.lineTo(ae-O,re(Pe.shoulderEnd)),C.quadraticCurveTo(ae-x*.99,re((Pe.bodyTop+Pe.shoulderEnd)/2),ae-x,re(Pe.bodyTop)),C.lineTo(ae-x,oe-Z),C.quadraticCurveTo(ae-x,oe,ae-x+Z,oe),C.lineTo(ae+x-Z,oe),C.quadraticCurveTo(ae+x,oe,ae+x,oe-Z),C.lineTo(ae+x,re(Pe.bodyTop)),C.quadraticCurveTo(ae+x*.99,re((Pe.bodyTop+Pe.shoulderEnd)/2),ae+O,re(Pe.shoulderEnd)),C.lineTo(ae+O,re(Pe.neckTop)),C.lineTo(ae+O+$,re(1))}function A(){let C=V.getContext("2d");C.setTransform(Q,0,0,Q,0,0),C.clearRect(0,0,X,ee);let W=C.createLinearGradient(0,0,0,be);W.addColorStop(0,`rgba(${s.beam},0.13)`),W.addColorStop(.75,`rgba(${s.beam},0.05)`),W.addColorStop(1,`rgba(${s.beam},0)`),C.fillStyle=W,C.beginPath(),C.moveTo(ae-ne(f)*1.6,0),C.lineTo(ae+ne(f)*1.6,0),C.lineTo(ae+ne(g)*1.8,be+ne(.03)),C.lineTo(ae-ne(g)*1.8,be+ne(.03)),C.closePath(),C.fill(),C.save(),C.translate(ae,be+ne(.012)),C.scale(1,.18);let oe=C.createRadialGradient(0,0,ne(.05),0,0,ne(.56));oe.addColorStop(0,`rgba(${s.beam},0.22)`),oe.addColorStop(1,`rgba(${s.beam},0)`),C.fillStyle=oe,C.beginPath(),C.arc(0,0,ne(.56),0,7),C.fill(),C.restore(),C.save(),C.translate(ae,be+ne(.012)),C.scale(1,.16);let Z=C.createRadialGradient(0,0,ne(.02),0,0,ne(.36));Z.addColorStop(0,"rgba(0,0,0,0.45)"),Z.addColorStop(1,"rgba(0,0,0,0)"),C.fillStyle=Z,C.beginPath(),C.arc(0,0,ne(.36),0,7),C.fill(),C.restore(),C.save(),C.clip(Ie);let x=C.createLinearGradient(0,re(1),0,be);x.addColorStop(0,"rgba(175,205,240,0.12)"),x.addColorStop(.7,"rgba(150,180,220,0.06)"),x.addColorStop(1,"rgba(120,150,200,0.10)"),C.fillStyle=x,C.fillRect(0,0,X,ee);let O=C.createLinearGradient(0,re(Pe.wall+.06),0,re(Pe.wall));O.addColorStop(0,"rgba(10,15,40,0)"),O.addColorStop(1,"rgba(10,15,40,0.30)"),C.fillStyle=O,C.fillRect(0,re(Pe.wall+.06),X,ne(.06)),C.restore()}function F(){let C=se.getContext("2d");C.setTransform(Q,0,0,Q,0,0),C.clearRect(0,0,X,ee),M(C),C.strokeStyle="rgba(205,232,255,0.55)",C.lineWidth=Math.max(1.5,ne(.007)),C.stroke(),C.strokeStyle="rgba(255,255,255,0.10)",C.lineWidth=Math.max(1,ne(.004)),C.stroke(Ie);let W=C.createLinearGradient(0,re(.7),0,re(.08));W.addColorStop(0,"rgba(255,255,255,0.16)"),W.addColorStop(1,"rgba(255,255,255,0.02)"),C.fillStyle=W,Oe(C,le(-g*.72),re(.7),ne(.055),ne(.62),ne(.027)),C.fill(),W=C.createLinearGradient(0,re(.62),0,re(.16)),W.addColorStop(0,"rgba(255,255,255,0.09)"),W.addColorStop(1,"rgba(255,255,255,0.01)"),C.fillStyle=W,Oe(C,le(g*.66),re(.62),ne(.028),ne(.46),ne(.014)),C.fill(),C.strokeStyle="rgba(255,255,255,0.14)",C.lineWidth=ne(.016),C.beginPath(),C.moveTo(le(-g*.9),re(Pe.bodyTop+.01)),C.quadraticCurveTo(le(-g*.8),re(Pe.shoulderEnd-.005),le(-f*1.15),re(Pe.shoulderEnd+.015)),C.stroke();let oe=ne(Pe.wall);C.fillStyle="rgba(255,255,255,0.07)",C.strokeStyle="rgba(215,240,255,0.6)",C.lineWidth=Math.max(1,ne(.005)),Oe(C,ae-ne(f)-oe*1.5,re(1),(ne(f)+oe*1.5)*2,ne(.03),ne(.008)),C.fill(),C.stroke(),C.strokeStyle="rgba(215,240,255,0.35)",C.beginPath(),C.ellipse(ae,re(.995),ne(f)*.92,ne(.012),0,0,Math.PI,!1),C.stroke();let Z=C.createRadialGradient(X/2,ee*.42,Math.min(X,ee)*.35,X/2,ee*.5,Math.max(X,ee)*.75);Z.addColorStop(0,"rgba(4,6,20,0)"),Z.addColorStop(1,"rgba(2,3,12,0.42)"),C.fillStyle=Z,C.fillRect(0,0,X,ee)}let P=new Set,te=0,j=[],q=[],he=[],Se=[],ue=0,Re=.03;function De(C){let W=w[C],oe=(W.out?K:J).getContext("2d");oe.setTransform(Q,0,0,Q,0,0);let Z=b(W),x=le(W.x),O=re(W.y);oe.drawImage(Ne.halo.c,x-Z.w*.72,O-Z.h*.72,Z.w*1.44,Z.h*1.44),H(oe,W,x,O,W.rot,1,1,1)}function Te(){if(Ne){for(let C of[J,K]){let W=C.getContext("2d");W.setTransform(Q,0,0,Q,0,0),W.clearRect(0,0,X,ee)}[...P].sort((C,W)=>C-W).forEach(De)}}function Ue(C){te=Math.max(0,Math.min(w.length,C)),j.length=0;let W=[...P].filter(Z=>Z>=te).sort((Z,x)=>x-Z);if(W.length){for(let Z=0;Z<W.length;Z++)he.push({i:W[Z],t:-Z*.02}),P.delete(W[Z]);Te()}let oe=new Set(q.map(Z=>Z.i));for(let Z=0;Z<te;Z++)!P.has(Z)&&!oe.has(Z)&&j.push(Z);if(j.length){let Z=Math.min(4.2,Math.max(.7,.4+j.length*.055));Re=Math.max(.02,Z/j.length),ue=Re}Rn()}function We(){let C=j.shift(),W=w[C],oe=!!W.out,Z=(oe?1.04:1.1)+a()*.12,x=Math.max(.02,f-Pe.coinR*1.2);q.push({i:C,t:0,dur:Math.sqrt(2*Math.max(.15,Z-W.y)/Pe.gravity),fromX:oe?W.x+(a()-.5)*.05:(a()-.5)*2*x,fromY:Z,spin:(a()-.5)*(oe?7:9),rot0:a()*Math.PI*2})}function it(){let C=ne(.06),W=ae-ne(Pe.jarW/2)-C,oe=re(1.03)-C,Z=(ne(Pe.jarW/2)+C)*2,x=be+ne(.02)-oe,O=document.createElement("canvas");O.width=Math.max(2,Math.ceil(Z*Q)),O.height=Math.max(2,Math.ceil(x*Q));let $=O.getContext("2d");return $.drawImage(J,W*Q,oe*Q,Z*Q,x*Q,0,0,O.width,O.height),$.drawImage(se,W*Q,oe*Q,Z*Q,x*Q,0,0,O.width,O.height),{c:O,w:Z,h:x}}function Ee(){if(!Ne)return;let C=Math.min(4,h);if(u.length!==C&&(u.length=0,C>0)){let W=J.getContext("2d");W.setTransform(Q,0,0,Q,0,0),W.clearRect(0,0,X,ee);for(let Z=0;Z<S.nIn;Z++)De(Z);let oe=it();for(let Z=0;Z<C;Z++){let x=h-C+Z;u.push({...oe,k:x%4,t:1})}Te()}}function ke(){let C=it();if(h++,u.length>=4&&u.shift(),u.push({...C,k:(h-1)%4,t:0}),te=0,j.length=0,q.length=0,he.length=0,P.clear(),Te(),Ot.clear(),lt=!1,Mt=!1,o.blip(),t({type:"event",kind:"rolloverDone",jarPct:0}),d=Math.max(0,d-1),d>0)qt(200);else if(p>=0){let W=p;p=-1,Ue(R(W))}Rn()}function Xe(C=90){if(r)return;let W=s.confetti;for(let oe=0;oe<C;oe++){let Z=-Math.PI/2+(a()-.5)*1.6,x=ne(.55)*(.5+a());Se.push({x:le((a()-.5)*f*1.6),y:re(Pe.neckTop)+(a()-.5)*ne(.04),vx:Math.cos(Z)*x,vy:Math.sin(Z)*x,life:1.5+a()*.5,decay:.32,gravMul:.4,rot:a()*Math.PI,spin:(a()-.5)*10,size:ne(.009)+a()*ne(.011),color:W[oe%W.length]})}Rn()}function Tt(C,W,oe=4){if(!r)for(let Z=0;Z<oe&&Se.length<240;Z++){let x=-Math.PI/2+(a()-.5)*2.2,O=ne(.25)*(.4+a()*.8);Se.push({x:C,y:W,vx:Math.cos(x)*O,vy:Math.sin(x)*O,life:1,rot:a()*Math.PI,size:ne(.008)+a()*ne(.008)})}}let Ce=.24;function ot(C){let W=!1;if(j.length){for(ue+=C;ue>=Re&&j.length;)ue-=Re,We();W=!0}for(let Z=q.length-1;Z>=0;Z--){let x=q[Z];if(x.t+=C,W=!0,x.t>=x.dur+Ce)if(q.splice(Z,1),x.i>=te)he.push({i:x.i,t:0});else{P.add(x.i),De(x.i),o.clink();let O=w[x.i],$=Math.max(0,Math.min(1,(B(P.size)-75)/25));Tt(le(O.x),re(O.y),4+Math.round($*4))}}for(let Z=he.length-1;Z>=0;Z--)he[Z].t+=C,W=!0,he[Z].t>.45&&he.splice(Z,1);for(let Z of u)Z.t<.9&&(Z.t+=C,W=!0);let oe=ne(2.2);for(let Z=Se.length-1;Z>=0;Z--){let x=Se[Z];if(x.life-=C*(x.decay!==void 0?x.decay:2.4),W=!0,x.life<=0){Se.splice(Z,1);continue}x.vy+=oe*(x.gravMul!==void 0?x.gravMul:1)*C,x.x+=x.vx*C,x.y+=x.vy*C,x.rot+=C*(x.spin!==void 0?x.spin:6)}return W}function Ke(C){for(let W of q){let oe=w[W.i];if(!!oe.out!==C)continue;let Z,x,O,$=1,ie=1;if(W.t<W.dur){let L=Math.min(1,W.t/W.dur),z=L*L*(3-2*L);if(Z=W.fromX+(oe.x-W.fromX)*Math.min(1,z/.9),x=Math.max(oe.y,W.fromY-.5*Pe.gravity*W.t*W.t),!C){let de=oe.type==="bill"||oe.type==="billup"?.088:.038,ve=_(Math.min(.97,x))-de-.004;ve>0&&(Z=Math.max(-ve,Math.min(ve,Z)))}O=W.rot0+W.spin*W.t+(oe.rot-W.rot0-W.spin*W.dur)*(L>.6?(L-.6)/.4:0)}else{let L=W.t-W.dur;Z=oe.x,x=oe.y+.028*Math.exp(-L*9)*Math.abs(Math.sin(L*22)),O=oe.rot;let z=.2*Math.exp(-L*13);$=1+z,ie=1-z}H(D,oe,le(Z),re(x),O,$,ie,1)}for(let W of he){let oe=w[W.i];if(!!oe.out!==C)continue;if(W.t<0){H(D,oe,le(oe.x),re(oe.y),oe.rot,1,1,1);continue}let Z=W.t/.45;H(D,oe,le(oe.x),re(oe.y+Z*Z*.5),oe.rot+Z,1,1,1-Z)}}function Ut(){if(Ne){D.setTransform(Q,0,0,Q,0,0),D.clearRect(0,0,X,ee),D.drawImage(V,0,0,X,ee);for(let C of u){let W=r?1:Math.min(1,C.t/.9),oe=W*W*(3-2*W),Z=C.k%2?1:-1,x=C.k>>1,O=ae+Z*me*(.56+x*.16),$=be-me*(.4+x*.045),ie=.38-x*.03,L=ae+(O-ae)*oe,z=be+($-be)*oe,de=1+(ie-1)*oe,ve=C.w*de,ye=C.h*de;D.save(),D.globalAlpha=.94,D.fillStyle="rgba(0,0,0,0.32)",D.beginPath(),D.ellipse(L,z,ve*.42,ye*.045,0,0,7),D.fill(),D.drawImage(C.c,L-ve/2,z-ye,ve,ye),D.restore()}D.save(),D.clip(Be),D.drawImage(J,0,0,X,ee),Ke(!1),D.restore(),D.drawImage(K,0,0,X,ee),Ke(!0);for(let C of Se){if(D.save(),D.globalAlpha=Math.max(0,Math.min(1,C.life)),D.translate(C.x,C.y),D.rotate(C.rot),C.color)D.fillStyle=C.color,D.fillRect(-C.size,-C.size*.6,C.size*2,C.size*1.2);else{D.fillStyle="#ffe9a8";let W=C.size*(1.6-C.life*.6);D.fillRect(-W,-W/3,W*2,W/1.5),D.fillRect(-W/3,-W,W/1.5,W*2)}D.restore()}D.drawImage(se,0,0,X,ee)}}let Et=0,N=0,ut=!1,Ct=1/60,lt=!1,Mt=!1,cn=[25,50,75,125,150,175],Ot=new Set,An=!1;function mi(C){if(Et=0,ut)return;let W=Math.min(.05,(C-N)/1e3)||.016;N=C,Ct+=(W-Ct)*.05;let oe=ot(W);Ut();let Z=B(P.size);for(let x of cn)Z>=x&&Z<(x<100?99.9:199.9)&&!Ot.has(x)?(Ot.add(x),Xe(28),o.blip(),t({type:"event",kind:"milestone",jarPct:x/100})):Z<x-8&&Ot.delete(x);P.size>=S.nIn&&S.nIn>0&&q.length===0&&!lt?(lt=!0,Xe(),o.chime(),t({type:"event",kind:"goalReached",jarPct:1})):P.size<S.nIn*.95&&(lt=!1),P.size===w.length&&w.length>S.nIn&&q.length===0&&d>0&&!Mt?(Mt=!0,Xe(),o.chime(),t({type:"event",kind:"zoneFull",jarPct:2}),m=C+(r?1e3:2300)):Z<190&&(Mt=!1,d===0&&(m=-1)),m>0&&C>=m&&(m=-1,ke()),An||(An=!0,i.ready()),Et=oe||m>0?requestAnimationFrame(mi):0}function Rn(){!Et&&!ut&&(N=performance.now(),Et=requestAnimationFrame(mi))}function gi(){if(X=e.clientWidth,ee=e.clientHeight,!X||!ee)return;Q=Math.min(devicePixelRatio||1,Pe.dprMax);for(let x of[G,J,K,V,se])x.width=Math.ceil(X*Q),x.height=Math.ceil(ee*Q);G.style.width=X+"px",G.style.height=ee+"px";let C=l.top+8,W=l.bottom+26,oe=Math.max(160,ee-C-W);me=Math.min(oe*.96,X*1.55),ae=((l.left||0)+(X-(l.right||0)))/2,be=ee-W-oe*.02,Be=U(!0),Ie=U(!1),Ne=T(),A(),F(),Te();let Z=u.length;u.length=0,(Z||h>0)&&Ee(),Ut()}let vi=0;addEventListener("resize",()=>{clearTimeout(vi),vi=setTimeout(gi,120)});function qt(C){C=Math.min(200,Math.max(0,Math.round(C||0))),te=R(C),j.length=0,q.length=0,he.length=0,P.clear();for(let W=0;W<te;W++)P.add(W);Te(),lt=te>=S.nIn&&te>0,Mt=te===w.length&&w.length>S.nIn,m=Mt&&d>0?performance.now()+2500:-1,Ot.clear();for(let W of cn)C>=W&&Ot.add(W);Ut(),m>0&&Rn()}function Jn(){if(d>0){h+=d,d=0;let C=p>=0?p:0;return p=-1,m=-1,C}return null}function er(){return Math.round(B(te))}function Rr(C){o.tada(),Xe((+C.deltaPct||0)>=.1?44:18);let W=Math.min(2,Math.max(0,+C.jarPctAfter||0))*100,oe=Math.max(0,Math.floor(C.rollovers||0));oe>0?(d+=oe,p=W,Ue(w.length)):d>0?p=W:Ue(R(W))}function Yt(C,W){d=0,p=-1,m=-1,h=Math.max(0,Math.floor(C.bankedJars||0)),Ee();let oe=Math.min(2,Math.max(0,+C.jarPct||0))*100;W?qt(oe):Ue(R(oe))}function xn(C){if(C.insets&&(l={top:0,bottom:0,...C.insets},gi()),C.theme!==void 0){let W=$i.find(oe=>oe.key===C.theme);W&&(s=W,ga(W),me>0&&(A(),F(),Ut()))}if(C.sound!==void 0&&o.setCoins(!!C.sound),C.tipSound!==void 0&&o.setFanfare(!!C.tipSound),C.notes!==void 0&&!!C.notes!==c){c=!!C.notes;let W=Jn(),oe=W!==null?W:er();S=y(),w=S.items,qt(oe),Ee()}}function gn(C){C=!!C,C!==ut&&(ut=C,ut?Et&&(cancelAnimationFrame(Et),Et=0):(Rn(),Ut()))}let Cn=Math.min(2,Math.max(0,i.state&&i.state.jarPct||0))*100;return gi(),Ee(),qt(Cn),An||(An=!0,i.ready()),{applyTip:Rr,syncState:Yt,setConfig:xn,setPaused:gn,jarPct:()=>Math.min(2,Math.max(0,B(te)/100)),perf:()=>({fps:ut?0:Et?Math.round(1/Ct):60,quality:Et?"2d":"idle"})}}var fi=Uh(),On=null,ms=[],Qd=!1,ep=!1;function Th(){On&&On.setPaused(Qd||ep)}var Gm=()=>.01+Math.random()*.035;function Vm(){if(!On)return;let i=On.jarPct(),e=Gm(),t=i+e,n=0;t>=2&&(n=1,t-=2),On.applyTip({deltaPct:e,jarPctAfter:t,rollovers:n})}function tp(i){switch(i.type){case"init":{if(On)return;let e=i.config||{},t=i.state||{},n=!!e.reducedMotion||matchMedia&&matchMedia("(prefers-reduced-motion: reduce)").matches,r={host:document.getElementById("stage"),config:e,state:t,reduced:n,emit:fi.emit,ready:()=>{fi.markReady();let a=ms;ms=[];for(let s of a)tp(s)}};On=(i.renderer==="2d"?$d:Jd)(r),Th();break}case"tip":if(!fi.isReady){ms.push(i);break}On.applyTip(i);break;case"syncState":if(!fi.isReady){ms.push(i);break}On.syncState(i.state||{},!!i.instant);break;case"setConfig":if(!fi.isReady){ms.push(i);break}On.setConfig(i.config||{});break;case"setPaused":Qd=!!i.paused,Th();break;case"demoPulse":fi.isReady&&Vm();break;default:break}}fi.onMessage=tp;document.addEventListener("visibilitychange",()=>{ep=document.hidden,Th()});setInterval(()=>{On&&fi.isReady&&fi.emit({type:"perf",...On.perf()})},5e3);fi.emit({type:"hello",protocol:1});})();
