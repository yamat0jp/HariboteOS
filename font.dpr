program font;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils, System.Classes;

type
  TFont = array [0..17] of Byte;

function font_A(data: array of Byte): TFont;
var
  tmp: TFont;
  i: integer;
begin
  for i := 0 to 16 do
    tmp[i] := data[i];
  result := tmp;
end;

var
  ms: TMemoryStream;
  f: TFont;

begin
  try
    { TODO -oUser -cConsole メイン : ここにコードを記述してください }
    f := font_A([$00, $18, $18, $18, $24, $24, $24, $24, $7E, $42, $42,
      $E7, $00, $00]);
    ms := TMemoryStream.Create;
    ms.WriteBuffer(f,SizeOf(f));
    ms.SaveToFile('hankaku.bin');
    ms.Free;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
