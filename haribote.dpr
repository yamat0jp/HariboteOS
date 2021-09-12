program haribote;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.Classes,
  ShellAPI;

{$I asmhead}
{$I objclasses}
procedure harimain; stdcall; forward;

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
  hdr: ^TMultiBoot_hdr;
  font: TFontClass;
  screen: TScreenClass;
begin
  hdr:=Pointer(0);
  // init_gdtidt;
  init_pic;
  init_palette;
  font := TFontClass.Create;
  screen := TScreenClass.Create;
  try
    font.putfont8_asc(0, 0, white, 'masasi fuke');
    screen.init_screen8(hdr^.width, hdr^.height);
  finally
    font.Free;
    screen.Free;
  end;
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
  multiboot_hdr: TMultiBoot_hdr;
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
    multiboot_hdr.screen_addr := Pointer($A0000);

    MemoryStream.Position := SizeOf(multiboot_hdr);
    dwSize := entry_addr - MemoryStream.Position;
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
    multiboot_hdr.font_addr := Pointer(MemoryStream.Position);
    MemoryStream.CopyFrom(fs, 0);
    FreeMem(pBuff, dwSize);

    MemoryStream.Position := 0;
    MemoryStream.WriteBuffer(multiboot_hdr, SizeOf(multiboot_hdr));
    MemoryStream.SaveToFile('Kernel.bin');
  finally
    MemoryStream.Free;
    fs.Free;
  end;
  LExePath := 'qemu-system-x86_64.exe';
  LParams := '-kernel Kernel.bin';
  ShellExecute(0, nil, pchar(LExePath), pchar(LParams), nil, 5);

end.
