library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity oneBitAdder is
    port (
        A: in STD_LOGIC;
        B: in STD_LOGIC;
        C: in STD_LOGIC;
        outC: out STD_LOGIC;
        S: out STD_LOGIC
    );
end oneBitAdder;

architecture arch of oneBitAdder is
begin
    outC <= (A and B) or (B and C) or (A and C);
    S <= (not A and B and not C) or (A and not B and not C) or (not A and not B and C) or (A and B and C);
end arch;