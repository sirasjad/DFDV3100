library IEEE;
use IEEE.STD_LOGIC_1164.all;

library util;
use util.all;
use util.motor.all;

entity cpu is
  port (
    clock, reset: in std_logic;
    left_motor, right_motor: out std_logic_vector(3 downto 0);
    pen_motor: out std_logic
  );
end cpu;

architecture cpu of cpu is
  signal data_bus: std_logic_vector(7 downto 0);

  -- Program counter signals
  signal pc_set, pc_enable: std_logic;
  signal pc_value: std_logic_vector(7 downto 0);

  -- Register R signals
  signal r_set, r_decrement: std_logic;
  signal r_value: std_logic_vector(7 downto 0);

  -- Motor driver signals
  signal motor_trigger, motor_moving: std_logic;
  signal motor_action: action_t;
  signal motor_steps: std_logic_vector(7 downto 0);

  signal pen_trigger, pen_down: std_logic;

  type FdeStateType is (fetch, decode, execute);
  signal fde_state: FdeStateType;

  -- State machine of the execution
  type ExecuteStateType is (ldr_0, ldr_1, decr, jrnz, move_0, move_1, pen_0, pen_1, empty);
  signal execute_state: ExecuteStateType;
begin
  rom: entity util.rom(generated) port map (
    address => pc_value, output => data_bus
  );

  -- In this design, all registers are synchronous components which are tied to
  -- the CPU clock. This means that we have to set the correct input to perform
  -- the action we want.
  pc: entity util.generic_register(sync) port map (
    clock => clock, data_input => data_bus, set => pc_set, increment => pc_enable,
    decrement => '0', output => pc_value, reset => reset
  );

  r: entity util.generic_register(sync) port map (
    clock => clock, data_input => data_bus, set => r_set, decrement => r_decrement,
    increment => '0', output => r_value, reset => '0'
  );

  -- The motor driver acts as a separate coprocessor, and starts executing the
  -- desired action when triggered. It will run in the background, allowing the
  -- CPU to keep executing instructions while the motor moves. This could have
  -- a mild to moderate performance improvement if many calculations have to be
  -- made.
  motor_driver: entity util.motor_driver(arch) port map (
    clock => clock, trigger => motor_trigger, steps => motor_steps, is_moving => motor_moving,
    action => motor_action, left_motor_signal => left_motor, right_motor_signal => right_motor,
    reset => reset, pen_signal => pen_motor, pen_trigger => pen_trigger, pen_down => pen_down
  );

  process(clock, reset)
  begin
    if reset = '1' then
      -- Reset and initialize everything
      fde_state <= fetch;
      execute_state <= empty;
      fde_state <= fetch;
      pc_enable <= '0';
      r_set <= '0';
      pc_set <= '0';
      r_decrement <= '0';
      motor_trigger <= '0';
      pen_down <= '0';
      pen_trigger <= '1';
    elsif rising_edge(clock) then
      -- Fetch decode execute cycle
      case fde_state is
        when fetch =>
          -- These settings should always be set this way when fetching. While
          -- not strictly necesarry, it simplifies the code as there are fewer
          -- states to go through while executing.
          pc_enable <= '0';
          pc_set <= '0';
          motor_trigger <= '0';
          pen_trigger <= '0';
          fde_state <= decode;

        when decode =>
          case data_bus is
            -- Read an opcode and set execute_state to the matching
            -- instruction. also performs the first micro operation needed to
            -- execute the instruction
            when x"00" => -- LD R
              pc_enable <= '1';
              execute_state <= ldr_0;
            when x"01" => -- DEC R
              r_decrement <= '1';
              execute_state <= decr;
            when x"02" => -- JRNZ
              pc_enable <= '1';
              execute_state <= jrnz;
            when x"03" =>  --MF
              motor_action <= MOVE_FORWARD;
              pc_enable <= '1';
              execute_state <= move_0;
            when x"04" =>  --MB
              motor_action <= MOVE_BACK;
              pc_enable <= '1';
              execute_state <= move_0;
            when x"05" =>  --MR
              motor_action <= MOVE_RIGHT;
              pc_enable <= '1';
              execute_state <= move_0;
            when x"06" =>  --ML
              motor_action <= MOVE_LEFT;
              pc_enable <= '1';
              execute_state <= move_0;
            when x"07" => -- PUP
              pen_down <= '0';
              execute_state <= pen_0;
            when x"08" => -- PDOWN
              pen_down <= '1';
              execute_state <= pen_0;
            when x"FF" => -- HALT
              execute_state <= empty;
            when others => -- Invalid instruction
              execute_state <= empty;
          end case;
          fde_state <= execute;

        when execute => case execute_state is
          when ldr_0 =>
            r_set <= '1';
            pc_enable <= '0';
            execute_state <= ldr_1;
          when ldr_1 =>
            r_set <= '0';
            pc_enable <= '1';
            fde_state <= fetch;
          when decr =>
            r_decrement <= '0';
            pc_enable <= '1';
            fde_state <= fetch;
          when jrnz =>
            if r_value = x"00" then
              pc_set <= '0';
              pc_enable <= '1'; --If we're not jumping we need to fetch the
                                --next instruction.
            else
              pc_set <= '1';
              pc_enable <= '0'; -- stay at the current address after jumping
            end if;
            fde_state <= fetch;
          when move_0 =>
            pc_enable <= '0';
            motor_trigger <= '0';
            execute_state <= move_1;
          when move_1 =>
            motor_steps <= data_bus;
            -- If the wheels are moving already, block execution until it has
            -- finished moving
            if motor_moving = '0' then
              motor_trigger <= '1';
              pc_enable <= '1';
              fde_state <= fetch;
            end if;
          when pen_0 =>
            -- Don't move the pen if the wheels are moving
            if motor_moving = '0' then
              execute_state <= pen_1;
            end if;
          when pen_1 =>
            pen_trigger <= '1';
            pc_enable <= '1';
            fde_state <= fetch;
          when empty => fde_state <= execute;
        end case;
      end case;
    end if;
  end process;
end cpu;
