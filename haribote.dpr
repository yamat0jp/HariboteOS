program haribote;

{$R *.res}

uses System.Classes;

const
  Blue = 1;
  Red = 4;
  Yellow = 14;
  White = 15;

type
  TMultiboot_hdr = packed record
    magic, flags, checksum: cardinal;
    header_addr, load_addr, load_end_addr, bss_end_addr, entry_addr: cardinal;
    mode_type: cardinal;
    width, height, depth: cardinal;
  end;

procedure harimain; stdcall; forward;

procedure loader; stdcall;
asm
  cli
  call harimain
  hlt
end;

procedure io_hlt; stdcall;
asm
  hlt
  ret
end;

procedure write_mem8(addr, data: integer); stdcall;
asm
  mov ecx,[esp+4]
  mov al,[esp+8]
  mov [ecx],al
  ret
end;

procedure harimain; stdcall;
var
  i: integer;
  p: ^TArray<Byte>;
begin
  for i := $000A0000 to $000AFFFF do
  begin
    p := Pointer(i);
    p^[i] := Byte(i and $0F);
  end;
  while True do
    io_hlt;
end;

procedure loader_end; stdcall;
begin

end;

var
  MemoryStream: TMemoryStream;
  pFunc, pBuff: Pointer;
  fwSize, dwSize: cardinal;
  multiboot_hdr: TMultiboot_hdr;
  image_base, image_size: integer;
  size: cardinal;
  entry_addr: integer;

begin
  image_base := $00400000;
  entry_addr := integer(@loader) - image_base;
  size := entry_addr - SizeOf(multiboot_hdr);
  image_size := size + $00001000;


  MemoryStream := TMemoryStream.Create;
  try
    FillChar(multiboot_hdr, SizeOf(multiboot_hdr), 0);
    multiboot_hdr.magic := $1BADB002;
    multiboot_hdr.flags := 1 shl 16;
    multiboot_hdr.checksum :=
      cardinal(-multiboot_hdr.magic - multiboot_hdr.flags);
    multiboot_hdr.header_addr := image_base;
    multiboot_hdr.load_addr := image_base;
    multiboot_hdr.load_end_addr := image_base + image_size;
    multiboot_hdr.bss_end_addr := image_base + image_size;
    multiboot_hdr.entry_addr := image_base + entry_addr;
    multiboot_hdr.mode_type := 0;
    multiboot_hdr.width := 0;
    multiboot_hdr.height := 0;
    multiboot_hdr.depth := 0;

    MemoryStream.WriteBuffer(multiboot_hdr, SizeOf(multiboot_hdr));
    dwSize := entry_addr - SizeOf(multiboot_hdr);
    pBuff := AllocMem(dwSize);
    MemoryStream.WriteBuffer(pBuff^, dwSize);
    FreeMem(pBuff, dwSize);

    pFunc := @loader;
    fwSize := cardinal(@loader_end) - cardinal(@loader);

    dwSize := $00001000 - fwSize;

    pBuff := AllocMem(dwSize);
    MemoryStream.WriteBuffer(pFunc^, fwSize);
    MemoryStream.WriteBuffer(pBuff^, dwSize);
    FreeMem(pBuff, dwSize);

    MemoryStream.SaveToFile('Kernel.bin');
  finally
    MemoryStream.Free;
  end;

end.
