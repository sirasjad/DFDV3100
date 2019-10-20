package motor is
  type action_t is (MOVE_LEFT, MOVE_RIGHT, MOVE_FORWARD, MOVE_BACK);
end package;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

library util;
use util.motor.all;
entity motor_driver is
  port (
    trigger: in std_logic; -- Async run command input
    clock: in std_logic; -- Board clock pulse
    action: in action_t; -- Action to perform
    steps: in std_logic_vector(7 downto 0); -- Amount of steps to perform for
                                            -- the MOVE_* actions.
    left_motor_signal, right_motor_signal: out std_logic_vector(3 downto 0);
    is_moving: out std_logic; -- High while executing a command
    reset: in std_logic;

    pen_down: in std_logic; --high if pen should be down, low otherwise
    pen_trigger: in std_logic; -- trigger pen to move

    pen_signal: out std_logic --PWM servo motor output
  );
end motor_driver;

architecture arch of motor_driver is

  --function doing a left bitwise rotation
  pure function rot_left(reg : std_logic_vector(3 downto 0)) return std_logic_vector is
  begin
    return reg(0) & reg(3) & reg(2) & reg(1);
  end function;

  -- function doing a right bitwise rotation
  pure function rot_right(reg : std_logic_vector(3 downto 0)) return std_logic_vector is
  begin
    return reg(2) & reg(1) & reg(0) & reg(3);
  end function;

  -- Counter used for timing of step_clock
  signal step_clock_counter: unsigned(18 downto 0);
  signal step_clock: std_logic;
  signal moving: std_logic; --Whether we're moving
  -- Counter for the amount of steps which are left to perform.
  signal step_counter: unsigned(7 downto 0);
  signal left_motor, right_motor: std_logic_vector(3 downto 0);
  signal left_dir, right_dir: std_logic;

  -- Servo driving signals
  signal servo_clock: std_logic; --  High pulse every 1 ms
  constant servo_timer_endpoint: integer := 50000 / 2; -- number to change
                                                       -- servo_clock at
  signal servo_clock_timer: unsigned(14 downto 0); -- counter for driving servo_clock

  signal servo_counter: unsigned(4 downto 0); -- Milliseconds used of the pwm period
  signal pen_is_down: std_logic; -- When high keep signal high for
                                 -- pen_up_period, pen_low_period otherwise
  constant pen_up_period: integer := 1;
  constant pen_down_period: integer := 3;
begin
  -- Stepper motor driver.
  process(trigger, moving, reset, steps, action, step_clock, left_dir, right_dir, right_motor, left_motor, step_counter, clock)
  begin
    if reset = '1' then
      moving <= '0';
      step_clock_counter <= (others => '0');
      left_motor <= "1100";
      right_motor <= "1100";
      step_counter <= to_unsigned(0, 8);
      step_clock <= '0';
    elsif rising_edge(clock) then
      if trigger = '1' and moving = '0' then
        step_clock_counter <= (others => '0');
        moving <= '1';
        step_counter <= unsigned(steps);
        case action is
          when MOVE_LEFT => left_dir <= '0'; right_dir <= '1';
          when MOVE_RIGHT => left_dir <= '1'; right_dir <= '0';
          when MOVE_FORWARD => left_dir <= '1'; right_dir <= '1';
          when MOVE_BACK => left_dir <= '0'; right_dir <= '0';
        end case;
      elsif step_clock = '1' and moving = '1' then
        -- Step motors once
        if left_dir = '0' then
          left_motor <= rot_left(left_motor);
        else
          left_motor <= rot_right(left_motor);
        end if;
        if right_dir = '0' then
          right_motor <= rot_left(right_motor);
        else
          right_motor <= rot_right(right_motor);
        end if;
        step_counter <= step_counter - 1;
        step_clock <= '0';

        -- Movement completed
        if step_counter = x"00" then
          moving <= '0';
        end if;
      end if;
      if moving = '1' then -- drive the step clock
        step_clock_counter <= step_clock_counter + 1;
        if step_clock_counter = 0 then
          step_clock <= '1';
        end if;
      end if;
    end if;
  end process;

  -- Only change pen state when triggered
  pen_is_down <= pen_down when pen_trigger = '1';

  process(clock, reset) --Drive servo_clock
  begin
    if reset = '1' then
      servo_clock <= '0';
      servo_clock_timer <= (others => '0');
    elsif rising_edge(clock) then
      servo_clock_timer <= servo_clock_timer + 1;
      if servo_clock_timer = servo_timer_endpoint then
        servo_clock <= not servo_clock;
        servo_clock_timer <= (others => '0');
      end if;
    end if;
  end process;

  process(servo_clock, pen_is_down) -- Drive the signal
  begin
    if reset = '1' then
      servo_counter <= (others => '0');
    elsif rising_edge(servo_clock) then
      if (pen_is_down = '1' and servo_counter <= pen_down_period)
        or (pen_is_down = '0' and servo_counter <= pen_up_period)
      then
        pen_signal <= '1';
      else
        pen_signal <= '0';
      end if;
      if servo_counter = 20 then
        servo_counter <= (others => '0');
      else
        servo_counter <= servo_counter + 1;
      end if;
    end if;
  end process;

  -- Set driver outputs
  is_moving <= moving;
  left_motor_signal <= left_motor;
  right_motor_signal <= right_motor;
end;
