library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity ALU is
    port(
        opA, opB: in std_logic_vector(3 downto 0);
        ctr: in std_logic_vector(2 downto 0);
        res: out std_logic_vector(4 downto 0)
    );
end ALU;

-- Architectural description using “if/then/else” statements:
architecture IfThenElse of ALU is
begin
    process(opA, opB, ctr)
        variable uopA, uopB: unsigned(4 downto 0);
        variable uopRes: unsigned(4 downto 0);
    begin
        uopA := unsigned('0' & opA);
        uopB := unsigned('0' & opB);
        if ctr = "000" then
            uopRes := uopA + uopB;
        elsif ctr = "001" then
            uopRes := uopA - uopB;
        elsif ctr = "010" then
            uopRes := uopA and uopB;
        elsif ctr = "011" then
            uopRes := uopA or uopB;
        elsif ctr = "100" then
            uopRes := '0' & uopA(4 downto 1);
        elsif ctr = "101" then
            uopRes := uopA(3 downto 0) & '0';
        elsif ctr = "110" then
            uopRes := '0' & uopB(4 downto 1);
        elsif ctr = "111" then
            uopRes := uopB(3 downto 0) & '0';
        end if;
        res <= std_logic_vector(uopRes);
    end process;
end IfThenElse;

-- Architectural description using “when/else” statements:
architecture WhenElse of ALU is
    signal uopRes: unsigned(4 downto 0);
    signal uopA, uopB: unsigned(4 downto 0);
begin
    uopRes <= (uopA + uopB) when ctr = "000" else
    (uopA - uopB) when ctr = "001" else
    (uopA and uopB) when ctr = "010" else
    (uopA or uopB) when ctr = "011" else
    ('0' & uopA(4 downto 1)) when ctr = "100" else
    (uopA(3 downto 0) & '0') when ctr = "101" else
    ('0' & uopB(4 downto 1)) when ctr = "110" else
    (uopB(3 downto 0) & '0') when ctr = "111";
    res <= std_logic_vector(uopRes);
end WhenElse;
