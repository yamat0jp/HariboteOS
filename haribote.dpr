program haribote;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.Classes,
  ShellAPI,
  Windows,
  IniFiles,
  asmhead;

type
  TOSMain = procedure; stdcall;

var
  MemoryStream, fs: TMemoryStream;
  p: Pointer;
  image_size, start, size, entry: cardinal;
  multiboot_hdr: TMultiBoot_hdr;
  image_base: integer;
  ini: TIniFile;
  LExePath, LParams: string;

begin
  MemoryStream := TMemoryStream.Create;
  fs := TMemoryStream.Create;
  ini := TIniFile.Create('data.ini');
  try
    fs.LoadFromFile('OSClasses.dll');
    image_base := $1000;
    start := ini.ReadInteger('address', 'start', image_base);
    entry:=start+image_base;
    image_size := SizeOf(TMultiboot_hdr) + fs.size - image_base + $00001000;
    multiboot_hdr.magic := $1BADB002;
    multiboot_hdr.flags := 1 shl 16;
    multiboot_hdr.checksum :=
      cardinal(-multiboot_hdr.magic - multiboot_hdr.flags);
    multiboot_hdr.header_addr := image_base;
    multiboot_hdr.load_addr := image_base;
    multiboot_hdr.load_end_addr := cardinal(image_base) + image_size;
    multiboot_hdr.bss_end_addr := cardinal(image_base) + image_size;
    multiboot_hdr.entry_addr := start;
    multiboot_hdr.mode_type := 0;
    multiboot_hdr.width := 360;
    multiboot_hdr.height := 280;
    multiboot_hdr.depth := 0;
    multiboot_hdr.screen_addr := Pointer($B8000);

    MemoryStream.WriteBuffer(multiboot_hdr, SizeOf(multiboot_hdr));
    fs.Position := entry;
    size := ini.ReadInteger('address', 'size', 0);
    MemoryStream.CopyFrom(fs, size);
    fs.Position := entry;
    p := AllocMem(size);
    fs.WriteBuffer(p, size);
    FreeMem(p);
    fs.Position := image_base;
    MemoryStream.CopyFrom(fs, fs.size - fs.Position);
    MemoryStream.SaveToFile('Kernel.bin');
  finally
    MemoryStream.Free;
    fs.Free;
    ini.Free;
  end;
  LExePath := 'qemu-system-x86_64.exe';
  LParams := '-kernel Kernel.bin';
  ShellExecute(0, nil, pchar(LExePath), pchar(LParams), nil, 5);

end.
