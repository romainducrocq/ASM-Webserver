# Web Server in Assembly
Creating a socket and sending an http request to localhost:8080 in fasm x86 Assembly.  
- fasm : https://flatassembler.net/  
- syscalls : https://chromium.googlesource.com/chromiumos/docs/+/HEAD/constants/syscalls.md  

### Hello
```
./fasm hello.asm && ./hello
```

### Web Server
```
./fasm webserver.asm && ./webserver
firefox http://localhost:8080/ &
```