
$samples_beat = sample_names(:bd)
$scales = scale_names
$bar = 4
$min_note_exp = 4

live_loop :main do
  puts :main
  sleep $bar
end

live_loop :bass_line do
  sync :main
  settings = refresh_beat_settings
  
  use_random_seed settings[:rhythm_seed]
  notes = settings[:notes]
  
  ($bar * notes - 1).times do
    do_sound = rand(0..1) > 0.5
    with_fx :pan, pan: rrand(-1,1) do
      play scale(scale(:d1, :minor_pentatonic).tick, :minor_pentatonic).choose, amp: 0.6# if do_sound
    end
    puts :bass
    sleep 1/notes
  end
end

live_loop :beat do
  sync :main
  settings = refresh_beat_settings
  
  use_random_seed settings[:rhythm_seed]
  notes = settings[:notes]
  
  ($bar * notes - 1).times do
    do_sound = rand(0..1) > 0.5
    with_fx :pan, pan: rrand(-1,1) do
      sample $samples_beat.choose if do_sound
    end
    puts :beat
    sleep 1/notes
  end
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
