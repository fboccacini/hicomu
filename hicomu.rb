
$samples_beat = sample_names(:bd)
$fxs = fx_names()
$scales = scale_names
$bar = 4
$min_note_exp = 4
$err_fx = []

live_loop :bass_line do
  #sync :main
  settings = refresh_bass_settings
  
  use_random_seed settings[:rhythm_seed]
  notes = settings[:notes]
  fx = $fxs.choose
  ($bar * notes).times do
    begin
      do_sound = rand(0..1) > 0.5
      with_fx :pan, pan: rrand(-1,1) do
        with_fx fx, $fx_settings[fx] do
          play scale(scale(:d1, :minor_pentatonic).tick, :minor_pentatonic).choose, amp: 0.6 if do_sound
        end
      end
      puts :bass
      puts fx
    rescue
      $err_fx.push fx
    end
    sleep 1/notes
  end
  puts :bass
  puts fx
end

live_loop :ambient do
  #sync :main
  settings = refresh_ambient_settings
  
  use_random_seed settings[:rhythm_seed]
  notes = settings[:notes]
  fx = $fxs.choose
  #($bar * notes).times do
  begin
    do_sound = rand(0..1) > 0.5
    with_fx :pan, pan: rrand(-1,1) do
      with_fx fx, $fx_settings[fx] do
        play scale(:d4, :minor_pentatonic).choose, amp: 0.4, attack: $bar * 0.3, release: $bar * 3
      end
    end
    puts :bass
    puts fx
  rescue
    $err_fx.push fx
  end
  sleep $bar * 4#1/notes
  #end
  puts :ambient
  puts fx
end

live_loop :beat do
  #sync :main
  settings = refresh_beat_settings
  
  use_random_seed settings[:rhythm_seed]
  notes = settings[:notes]
  
  ($bar * notes).times do
    do_sound = rand(0..1) > 0.5
    with_fx :pan, pan: rrand(-1,1) do
      sample $samples_beat.choose if do_sound
    end
    puts $err_fx
    sleep 1/notes
  end
  puts :beat
end

def refresh_ambient_settings
  settings = {
    bars_change: 8,
    bpm:  time_cycle(cycle: :hour,
                     cycle_length: 1,
                     step: :minute,
                     step_length: 1,
                     max: 120,
                     min: 60,
                     round: true,
                     circle: true
                     ),
    notes: (2 ** time_cycle(cycle: :hour,
                            cycle_length: 1,
                            step: :minute,
                            step_length: 1,
                            max: $min_note_exp,
                            min: 0,
                            round: true,
                            circle: false
                            )) * 1.0,
    rhythm_seed: time_cycle(cycle: :hour,
                            cycle_length: 1,
                            step: :minute,
                            step_length: 3,
                            max: 65535,
                            min: 0,
                            round: false
                            )
  }
  
  set(:bpm, settings[:bpm]) if get(:bpm) != settings[:bpm]
  
  return settings
end

def refresh_beat_settings
  settings = {
    bars_change: 8,
    bpm:  time_cycle(cycle: :hour,
                     cycle_length: 1,
                     step: :minute,
                     step_length: 1,
                     max: 120,
                     min: 60,
                     round: true,
                     circle: true
                     ),
    notes: (2 ** time_cycle(cycle: :hour,
                            cycle_length: 1,
                            step: :minute,
                            step_length: 1,
                            max: $min_note_exp,
                            min: 0,
                            round: true,
                            circle: false
                            )) * 1.0,
    rhythm_seed: time_cycle(cycle: :hour,
                            cycle_length: 1,
                            step: :minute,
                            step_length: 2,
                            max: 65535,
                            min: 0,
                            round: false
                            )
  }
  
  set(:bpm, settings[:bpm]) if get(:bpm) != settings[:bpm]
  
  return settings
end

def refresh_bass_settings
  settings = {
    bars_change: 8,
    bpm:  time_cycle(cycle: :hour,
                     cycle_length: 1,
                     step: :minute,
                     step_length: 1,
                     max: 120,
                     min: 60,
                     round: true,
                     circle: true
                     ),
    notes: (2 ** time_cycle(cycle: :hour,
                            cycle_length: 1,
                            step: :minute,
                            step_length: 1,
                            max: $min_note_exp,
                            min: 0,
                            round: true,
                            circle: false
                            )) * 1.0,
    rhythm_seed: time_cycle(cycle: :hour,
                            cycle_length: 1,
                            step: :minute,
                            step_length: 1,
                            max: 65535,
                            min: 0,
                            round: false
                            )
  }
  
  set(:bpm, settings[:bpm]) if get(:bpm) != settings[:bpm]
  
  return settings
end

def time_cycle(
    time: Time.now,
    cycle: :hour,
    cycle_length: 1,
    step: :minute,
    step_length: 1,
    max: 1,
    min: 0,
    round: false,
    circle: false
  )
  
  case cycle
  when :week
    total_cycle = 7 * 24 * 3600 * cycle_length
    time += 3600 * 24 * 3 # Adjust weekday
  when :day
    total_cycle = 24 * 3600 * cycle_length
  when :hour
    total_cycle = 3600 * cycle_length
  end
  
  case step
  when :day
    total_step = 24 * 3600 * step_length
  when :hour
    total_step = 3600 * step_length
  when :minute
    total_step = 60 * step_length
  end
  
  total_cycle = total_cycle.to_f
  total_cycle /= 2 if circle
  
  #puts "#{time.to_datetime} #{time.to_i + time.gmt_offset} % #{total_cycle}"
  part = (time.to_i + time.gmt_offset) % total_cycle
  #puts "part: #{part}"
  steps = part.to_i / total_step
  #puts "#{part.to_i} / #{total_step}"
  #puts "steps: #{steps}"
  rate = (total_step * steps) / total_cycle
  if circle
    puts "rate: #{rate}"
    rate = 1.0 - (0.5 - rate).abs * 2
    puts "rate: #{rate}"
  end
  #puts "#{total_cycle.to_f} / #{(total_step * steps)}"
  #puts "rate: #{rate}"
  
  result = min + (max - min) * rate
  result = result.floor if round
  #puts "result: #{round ? result.floor : result}"
  
  
  return result
  
end

def get_beats
  return ((get(:bpm).to_f / 60) * 4)
end


$fx_settings = Hash.new
fx_temp = $fxs.to_a
fx_temp.delete(:record)
$fxs = fx_temp.ring
$fxs.each { |name| $fx_settings[name] = Hash.new }
#bname = ("record_buf")
#$fx_settings[:record] = {
#  buffer: buffer(bname,8)
#}