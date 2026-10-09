#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
PORT="${PORT:-3000}"
export PORT
PROJECT_ROOT="$(pwd)"
export PROJECT_ROOT
DIST_DIR="$PROJECT_ROOT/dist"
export DIST_DIR
: "${OPENCODE_WEB_DIR:?OPENCODE_WEB_DIR must be set}"
/usr/bin/time -p mkdir -p "$DIST_DIR" "$OPENCODE_WEB_DIR"
/usr/bin/time -p bash -n start.sh
if [ -f "$PROJECT_ROOT/package.json" ]; then
  /usr/bin/time -p npm install --no-audit --no-fund
  if /usr/bin/time -p node -e 'try{const p=JSON.parse(require("fs").readFileSync("package.json","utf8"));process.exit(p.scripts&&p.scripts.build?0:1)}catch(e){process.exit(1)}'; then
    /usr/bin/time -p npm run build
  fi
fi
if [ ! -f "$DIST_DIR/index.html" ]; then
  /usr/bin/time -p cp -f "$PROJECT_ROOT/index.html" "$DIST_DIR/index.html"
else
  /usr/bin/time -p bash -c 'if [ -f "$PROJECT_ROOT/index.html" ] && [ "$PROJECT_ROOT/index.html" -nt "$DIST_DIR/index.html" ]; then cp -f "$PROJECT_ROOT/index.html" "$DIST_DIR/index.html"; fi'
fi
/usr/bin/time -p node -e 'const fs=require("fs"),path=require("path");const project=process.env.PROJECT_ROOT||process.cwd();const dir=process.env.DIST_DIR||path.join(project,"dist");const out=process.env.OPENCODE_WEB_DIR;if(!out){console.error("OPENCODE_WEB_DIR must be set");process.exit(1)}const payload={project:path.resolve(project),directory:path.resolve(dir)};fs.mkdirSync(out,{recursive:true});fs.writeFileSync(path.join(out,"deployment-output.json"),JSON.stringify(payload));console.log("deployment-output:",JSON.stringify(payload))'
exec /usr/bin/time -p node -e '
const http=require("http"),fs=require("fs"),path=require("path");
const root=process.env.DIST_DIR||path.join(process.cwd(),"dist");
const port=Number(process.env.PORT||3000);
const mime={".html":"text/html; charset=utf-8",".js":"application/javascript; charset=utf-8",".css":"text/css; charset=utf-8",".json":"application/json",".svg":"image/svg+xml",".png":"image/png",".jpg":"image/jpeg",".jpeg":"image/jpeg",".webp":"image/webp",".ico":"image/x-icon",".txt":"text/plain; charset=utf-8",".wasm":"application/wasm"};
const server=http.createServer((req,res)=>{
  try{
    const u=new URL(req.url,"http://localhost");
    let rel=decodeURIComponent(u.pathname);
    if(rel.includes("\0")){res.writeHead(400);res.end();return}
    let file=path.resolve(root,"."+rel);
    if(file!==path.resolve(root)&&!file.startsWith(path.resolve(root)+path.sep)){res.writeHead(404);res.end("Not found");return}
    let stat=null;try{stat=fs.statSync(file)}catch(e){stat=null}
    if(stat&&stat.isDirectory()) file=path.join(file,"index.html");
    if(!stat&&!path.extname(file)) file=path.join(root,"index.html");
    if(!fs.existsSync(file)){res.writeHead(404);res.end("Not found");return}
    const ext=path.extname(file).toLowerCase();
    res.setHeader("Content-Type",mime[ext]||"application/octet-stream");
    res.setHeader("Cache-Control","no-cache");
    const data=fs.readFileSync(file);
    res.writeHead(200,{"Content-Length":data.length});
    if(req.method==="HEAD"){res.end();return}
    res.end(data);
  }catch(e){res.writeHead(500);res.end("Error")}
});
server.listen(port,"0.0.0.0",()=>console.log("PlayGround static server listening on "+port+" serving "+root));
'
