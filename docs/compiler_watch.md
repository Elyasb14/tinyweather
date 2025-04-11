# Compiler watching

Zig has a nice feature that allows it to watch the filesystem and build automatically using the following feature.

```bash
zig build -Dno-bin -fincremental --watch
```
As of now this onyl shows compiler errors, it does not produce a binary.
