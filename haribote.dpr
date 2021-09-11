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
  vram: PByte;
  xsize, ysize: integer;
  info: ^TBootInfo;

  i: integer;
  screen: PByte;
begin
  info := Pointer($00);
  vram := info^.vram;
  xsize := info^.scrnx;
  ysize := info^.scrny;
  init_gdtidt;
  init_pic;

  init_palette;
  init_screen8(vram, xsize, ysize);

  //test
  screen := Pointer($000a0000);
  for i := 0 to $0000FFFF do
    screen[i] := i and $0F;

  while True do
    io_hlt;
end;

procedure loader_end; stdcall;
begin

end;

var
  MemoryStream, fs: TMemoryStream;
  pFunc, pBuff: Pointer;
  fwSize, dwSize, image_size: cardinal;
  info: TBootInfo;
  LExePath, LParams: string;

begin
  MemoryStream := TMemoryStream.Create;
  fs := TMemoryStream.Create;
  try
    info.vram := Pointer($E0000000);
    info.scrnx := 256;
    info.scrny := 256;
    image_size:=$10000;
    MemoryStream.WriteBuffer(info, SizeOf(TBootInfo));
    dwSize := image_size - SizeOf(TBootInfo);
    pBuff := AllocMem(dwSize);
    MemoryStream.WriteBuffer(pBuff^, dwSize);
    FreeMem(pBuff, dwSize);

    pFunc := @loader;
    fwSize := cardinal(@loader_end) - cardinal(@loader);
    fs.LoadFromFile('hankaku.bin');

    image_size := $00100000;
    dwSize := image_size - fwSize- fs.Size;

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
  LExePath := 'qemu-system-i386.exe';
  LParams := '-kernel Kernel.bin';
  ShellExecute(0, nil, PChar(LExePath), PChar(LParams), nil, 5);

end.
