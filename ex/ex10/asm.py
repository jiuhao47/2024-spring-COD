from pwn import *

copy_inject = [
    "lui  $8,0x4444",
    "ori  $8,$8,0x4444",
    "lui	$9,0x8000",
    "addiu	$9,$9,0x8f30",
    "sw $8, 0($9)",
]

copy_rop = [
    "lui  $8,0x5555",
    "ori  $8,$8,0x5555",
    "lui	$9,0x8000",
    "addiu	$9,$9,0x8f34",
    "sw $8, 0($9)",
    # "j _halt",
]

password_inject = [
    "lui  $8,0x6666",
    "ori  $8,$8,0x6666",
    "lui	$9,0x8000",
    "addiu	$9,$9,0x8f00",
    "sw $8, 0($9)",
]
select_func1 = {
    "lui  $8,0x1111",
    "ori  $8,$8,0x1111",
    "lui	$9,0x8000",
    "addiu	$9,$9,0x8f10",
    "sw $8, 0($9)",
}


def translate_mips_to_machine(mips_instruction):
    # 使用pwn库的asm函数将MIPS指令翻译为机器指令
    machine_instruction = asm(mips_instruction, arch="mips")

    # 将机器指令转化为十六进制表示
    hex_instruction = machine_instruction

    return str(hex_instruction.hex())


for input_code in select_func1:
    asm_code = translate_mips_to_machine(input_code)
    print("".join("\\x" + asm_code[i : i + 2] for i in range(0, len(asm_code), 2)))
