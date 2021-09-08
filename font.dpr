program font;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils, System.Classes;

function font_A(data: array of Byte): Char;
var
  tmp: array [0 .. 15] of Byte;
  i: integer;
begin
  for i := 0 to 15 do
    tmp[i] := data[i];
  result := Char(addr(tmp)^);
end;

var
  ms: TMemoryStream;

begin
  try
    { TODO -oUser -cConsole メイン : ここにコードを記述してください }
    ms := TMemoryStream.Create;
    ms.WriteData(font_A([$00, $18, $18, $18, $24, $24, $24, $24, $7E, $42, $42,
      $E7, $00, $00]));
    ms.SaveToFile('hankaku.bin');
    ms.Free;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
