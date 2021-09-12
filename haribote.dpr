program haribote;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.Classes,
  ShellAPI;

{$I asmhead}
procedure harimain; stdcall; forward;
procedure inthandler21(esp: integer); stdcall; forward;

procedure loader; stdcall;
asm
  cli
  call harimain
  hlt
end;

{$I naskfunc}
{$I graph}
{$I bootpack}

procedure harimain; stdcall;
var
  xsize, ysize: integer;
  hdr: ^TMultiBoot_hdr;
    i: Integer;
    vram: pbyte;
begin
  hdr:=Pointer(0);
  xsize:=hdr.width;
  ysize:=hdr.height;
{
  init_gdtidt;
  init_pic;

  init_palette;
  init_screen8(screen, xsize, ysize);}
  vram:=screen;
  for i := 0 to $ffff do
    vram[i]:=i and yellow;
  while True do
    io_hlt;
end;

procedure loader_end; stdcall;
begin

end;

var
  MemoryStream, fs: TMemoryStream;
  pFunc, pBuff: Pointer;
  fwSize, dwSize, image_size, size: cardinal;
  info: TBootInfo;
  multiboot_hdr: TMultiboot_hdr;
  image_base, entry_addr: integer;
  LExePath, LParams: string;

begin
  MemoryStream := TMemoryStream.Create;
  fs := TMemoryStream.Create;
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
    multiboot_hdr.load_end_addr := cardinal(image_base) + image_size;
    multiboot_hdr.bss_end_addr := cardinal(image_base) + image_size;
    multiboot_hdr.entry_addr := image_base + entry_addr;
    multiboot_hdr.mode_type := 0;
    multiboot_hdr.width := 256;
    multiboot_hdr.height := 256;
    multiboot_hdr.depth := 0;

    info.vram := Pointer($E0000000);
    info.scrnx := 256;
    info.scrny := 256;

    MemoryStream.WriteBuffer(multiboot_hdr, SizeOf(multiboot_hdr));
    dwSize := entry_addr - SizeOf(TMultiboot_hdr);
    pBuff := AllocMem(dwSize);
    MemoryStream.WriteBuffer(pBuff^, dwSize);
    FreeMem(pBuff, dwSize);

    pFunc := @loader;
    fwSize := cardinal(@loader_end) - cardinal(@loader);
    fs.LoadFromFile('hankaku.bin');

    image_size := $1000;
    dwSize := image_size - fwSize - fs.size;

    pBuff := AllocMem(dwSize);
    MemoryStream.WriteBuffer(pFunc^, fwSize);
    MemoryStream.WriteBuffer(pBuff^, dwSize);
    MemoryStream.CopyFrom(fs, 0);
    FreeMem(pBuff, dwSize);

    MemoryStream.SaveToFile('Kernel.bin');
  finally
    MemoryStream.Free;
    fs.Free;
  end;
  LExePath := 'qemu-system-x86_64.exe';
  LParams := '-kernel Kernel.bin';
  ShellExecute(0, nil, PChar(LExePath), PChar(LParams), nil, 5);

end.
