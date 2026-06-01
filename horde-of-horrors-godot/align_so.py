import sys
import struct

def align_elf(file_path):
    with open(file_path, 'rb+') as f:
        data = f.read(64)
        if data[:4] != b'\x7fELF':
            return
        
        elf_class = data[4] # 1 = 32-bit, 2 = 64-bit
        is_64 = elf_class == 2
        
        if is_64:
            ph_off = struct.unpack('<Q', data[32:40])[0]
            ph_entsize = struct.unpack('<H', data[54:56])[0]
            ph_num = struct.unpack('<H', data[56:58])[0]
        else:
            ph_off = struct.unpack('<I', data[28:32])[0]
            ph_entsize = struct.unpack('<H', data[42:44])[0]
            ph_num = struct.unpack('<H', data[44:46])[0]
            
        f.seek(ph_off)
        for i in range(ph_num):
            ph_data = f.read(ph_entsize)
            p_type = struct.unpack('<I', ph_data[:4])[0]
            
            if p_type == 1: # PT_LOAD
                # In 64-bit, p_align is at offset 48 (last 8 bytes of 56-byte header)
                # In 32-bit, p_align is at offset 28 (last 4 bytes of 32-byte header)
                if is_64:
                    f.seek(ph_off + i * ph_entsize + 48)
                    f.write(struct.pack('<Q', 16384))
                else:
                    f.seek(ph_off + i * ph_entsize + 28)
                    f.write(struct.pack('<I', 16384))
            
            f.seek(ph_off + (i + 1) * ph_entsize)

if __name__ == '__main__':
    for arg in sys.argv[1:]:
        print(f"Aligning {arg}...")
        align_elf(arg)
