procedure io_hlt; stdcall;
asm
  hlt
  ret
end;

procedure io_cli; stdcall;
asm
  cli
  ret
end;

procedure io_sti; stdcall;
asm
  sti
  ret
end;

procedure io_stihlt; stdcall;
asm
  sti
  hlt
  ret
end;

function io_in8(port: integer): Int8; stdcall;
asm
  mov edx,  port
  mov eax,  0
  in  al, dx
  ret
end;

function io_in16(port: integer): Int16; stdcall;
asm
  mov edx,  port
  mov eax,  0
  in  ax,  dx
  ret
end;

function io_in32(port: integer): Int32; stdcall;
asm
  mov edx,  port
  in  eax,  dx
  ret
end;

function io_out8(port, data: integer): integer; stdcall;
asm
  mov edx,  port
  mov eax,  data
  out dx, al
  ret
end;

function io_out16(port, data: integer): Int16; stdcall;
asm
  mov edx,  port
  mov eax,  data
  out dx, ax
  ret
end;

function io_out32(port, data: integer): Int32; stdcall;
asm
  mov edx,  port
  mov eax,  data
  out dx, eax
  ret
end;

function io_load_eflags: integer; stdcall;
asm{
  pushfd
  pop eax
  ret}
end;

function io_store_eflags(port: integer): integer; stdcall;
asm{
  mov eax,  port
  push  eax
  popfd
  ret}
end;

procedure load_gdtr(limit, addr: integer);
asm
  mov eax, limit
  mov addr,  eax
  lgdt  WORD [addr]
  ret
end;

procedure load_idtr(limit, addr: integer);
asm
  mov eax,  limit
  mov addr,  eax
  lidt  WORD [addr]
  ret
end;

procedure asm_inthandler21; stdcall;
asm{
  push  es
  push  ds
  pushad
  mov eax,  esp
  push  eax
  mov ax, ss
  mov ds, ax
  mov es, ax
  call  inthandler21
  pop eax
  popad
  pop ds
  pop es
  iretd}
end;


