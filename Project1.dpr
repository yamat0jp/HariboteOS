program Project1;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  classes;

type
  TMultiboot_hdr = packed record
    magic, flags, checksum: cardinal;
    header_addr, load_addr, load_end_addr, bss_end_addr, entry_addr: cardinal;
    mode_type: cardinal;
    width, height, depth: cardinal;
    screen_addr, font_addr: Pointer;
  end;

var
  ms: tmemorystream;
  hdr: tmultiboot_hdr;
begin
  try
    { TODO -oUser -cConsole メイン : ここにコードを記述してください }
    ms:=tmemorystream.Create;
    ms.LoadFromFile('kernel.bin');
    ms.ReadBuffer(hdr,sizeof(tmultiboot_hdr));
    ms.Free;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
