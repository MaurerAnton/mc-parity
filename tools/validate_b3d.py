#!/usr/bin/env python3
"""Validate a .b3d by walking its chunk tree exactly like Luanti's
CB3DMeshFileLoader (NUL-terminated strings, size = data length)."""
import struct, sys

def walk(path):
    data = open(path, "rb").read()
    pos = 0
    def rd(fmt):
        nonlocal pos
        v = struct.unpack_from("<" + fmt, data, pos)
        pos += struct.calcsize("<" + fmt)
        return v[0] if len(v) == 1 else v
    def rdstr():
        nonlocal pos
        end = data.index(b"\x00", pos)
        s = data[pos:end].decode(errors="replace")
        pos = end + 1
        return s
    def header():
        nonlocal pos
        name = data[pos:pos + 4].decode(errors="replace")
        pos += 4
        size = rd("i")
        start = pos - 8
        return name, size, start
    def skip(start, size):
        nonlocal pos
        pos = start + 8 + size

    assert data[0:4] == b"BB3D", f"{path}: not BB3D"
    pos = 4  # magic consumed (C++ reads it as part of the chunk header)
    main_size = rd("i")
    version = rd("i")
    assert version == 1, f"{path}: version {version}"
    out = [f"== {path}: main_data={main_size} version={version} file={len(data)}"]
    n_texs = n_brus = n_node = n_mesh = n_vrts = n_tris = 0
    verts = tris_n = 0

    def read_node(cstart, csize):
        nonlocal n_node, n_mesh, n_vrts, n_tris, verts, tris_n, pos
        n_node += 1
        rdstr(); rd("fff"); rd("fff"); rd("ffff")
        while cstart + csize > pos:
            name, size, start = header()
            if name == "NODE":
                read_node(start, size)
            elif name == "MESH":
                n_mesh += 1
                rd("i")
                while start + size > pos:
                    name2, size2, start2 = header()
                    if name2 == "VRTS":
                        n_vrts += 1
                        flags, tcsets, tcsize = rd("iii")
                        per = 3 + (3 if flags & 1 else 0) + (4 if flags & 2 else 0) + tcsets * tcsize
                        verts += (size2 - 12) // (per * 4)
                        pos = start2 + 8 + size2
                    elif name2 == "TRIS":
                        n_tris += 1
                        tris_n += (size2 - 4) // 12
                        pos = start2 + 8 + size2
                    else:
                        pos = start2 + 8 + size2
            else:
                pos = start + 8 + size

    while main_size > pos:  # main chunk start=0, size = data length
        name, size, start = header()
        if name == "TEXS":
            n_texs += 1
            while start + size > pos:
                rdstr(); rd("ii"); rd("fffff")
        elif name == "BRUS":
            n_brus += 1
            n = rd("i")
            for _ in range(n):
                rdstr(); rd("ffff"); rd("f"); rd("ii")
                for _ in range(min(n, 3)):  # texture ids (MATERIAL_MAX_TEXTURES)
                    rd("i")
        elif name == "NODE":
            read_node(start, size)
        else:
            pos = start + 8 + size

    out.append(f"   TEXS={n_texs} BRUS={n_brus} NODE={n_node} MESH={n_mesh} VRTS={n_vrts} TRIS={n_tris}")
    out.append(f"   verts={verts} tris={tris_n} end={pos} eof={len(data)} "
               + ("OK" if pos <= len(data) else "OVERREAD!"))
    print("\n".join(out))

for p in sys.argv[1:]:
    walk(p)
