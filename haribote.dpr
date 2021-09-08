program haribote;

{$APPTYPE CONSOLE}
{$R *.res}

uses System.Classes, ShellAPI;

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

function screen: PByte; stdcall;
begin
  result := PByte($000B8000);
end;

procedure putfont8(x, y: integer; color: Byte; font: Pointer); stdcall;
type
  TFont = array [0 .. 16] of Byte;
var
  i: integer;
  pdata: ^TFont;
  b: Byte;
  p: PByte;
  xsize: integer;
begin
  pdata := font;
  xsize := 360;
  for i := 0 to 16 do
  begin
    p := screen + (y + i) * xsize + x;
    b := pdata^[i];
    if b and $80 <> 0 then
      p[0] := color;
    if b and $40 <> 0 then
      p[1] := color;
    if b and $20 <> 0 then
      p[2] := color;
    if b and $10 <> 0 then
      p[3] := color;
    if b and $08 <> 0 then
      p[4] := color;
    if b and $04 <> 0 then
      p[5] := color;
    if b and $02 <> 0 then
      p[6] := color;
    if b and $01 <> 0 then
      p[7] := color;
  end;
end;

procedure harimain; stdcall;
var
  i: integer;
begin
  for i := 0 to 80 * 25 do
  begin
    screen[2 * i] := 255;
    screen[2 * i + 1] := 255;
  end;
  putfont8(8, 8, 0, Pointer($0000C520 + 8 * 1));
  while true do
    io_hlt;
end;

procedure loader_end; stdcall;
begin

end;

var
  MemoryStream, fs: TMemoryStream;
  pFunc, pBuff: Pointer;
  fwSize, dwSize: cardinal;
  multiboot_hdr: TMultiboot_hdr;
  image_base, image_size: integer;
  size: cardinal;
  entry_addr: integer;
  LExePath, LParams: string;

begin
  image_base := $00400000;
  entry_addr := integer(@loader) - image_base;
  size := entry_addr - SizeOf(multiboot_hdr);
  image_size := size + $00001000;

  MemoryStream := TMemoryStream.Create;
  fs := TMemoryStream.Create;
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

    fs.LoadFromFile('hankaku.bin');
    fs.Position := 0;
    MemoryStream.CopyFrom(fs, 0);

    MemoryStream.SaveToFile('Kernel.bin');
  finally
    MemoryStream.Free;
    fs.Free;
  end;
  LExePath := 'qemu-system-x86_64.exe';
  LParams := '-kernel Kernel.bin';
  ShellExecute(0, nil, PChar(LExePath), PChar(LParams), nil, 5);

end.
