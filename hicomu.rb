
$samples_beat = sample_names(:bd)
$scales = scale_names
$main_tone = :d
beats = 8

beat_notes = Array.new(beats){ |n| {note: nil, duration: 1} }
set_beat_notes = Array.new

live_loop :beat do
  settings = refresh_beat_settings
  puts settings
  
  use_bpm get(:bpm)
  use_random_seed settings[:rythm_seed]
  
  intervals = (ring 1, 1/2.0, 1/4.0, 1/8.0)
  puts set_beat_notes.inspect
  if set_beat_notes.length < settings[:notes]
    (settings[:notes] - set_beat_notes.length).times do
      available_pos = Array.new(beats){ |n=0| n }
      puts "#{set_beat_notes.length} < #{settings[:notes]}"
      puts beats
      puts available_pos.inspect
      available_pos -= set_beat_notes
      puts available_pos.inspect
      puts set_beat_notes.inspect
      pos = available_pos[rrand_i(0,available_pos.length - 1)]
      r = rrand_i(-1,$samples_beat.length-1)
      beat_notes[pos] = {note: r == -1 ? nil : $samples_beat[r], duration: intervals.choose}
      set_beat_notes << pos
    end
  end
  
  if set_beat_notes.length > settings[:notes]
    (set_beat_notes.length - settings[:notes]).times do
      beat_notes[set_beat_notes.delete_at(-1)][:note] = nil
    end
  end
  
  puts beat_notes.inspect
  beat_notes.each do |note|
    puts note
    puts get(:bpm)
    sample note[:note]
    sleep note[:duration]
  end
end


live_loop :ambient do
  
  sync :beat
  
  use_bpm get(:bpm)
  
  settings = refresh_ambient_settings
  puts settings.inspect
  #use_random_seed $settings[:rythmseed]
  notes = (ring 1, 1/2.0, 1/4.0, 1/8.0).shuffle
  amb_scale = $scales[settings[:scale]]
  puts amb_scale
  
  
  #with_fx :whammy, pitch: 5, time_dis: 6 do
  with_fx :panslicer, pan_max: 1.0, pan_min: -1.0, phase: beats, wave: 2 do
    play scale(:d2, amb_scale, octaves: 2).choose, attack: beats / 8, sustain: beats / 4, release: beats / 2 + beats / 4, amp: 0.3
  end
  #end
end

live_loop :arpeggio do
  sync :beat
  
  use_bpm get(:bpm)
  settings = refresh_arpeggio_settings
  
  puts settings.inspect
  
  use_random_seed settings[:rythm_seed]
  notes = (ring 1, 1/2.0, 1/4.0).shuffle
  arp_scale = $scales[settings[:scale]]
  sleep 1
  8.times do
    with_fx :pan, pan: rrand(-1,1) do
      play scale(scale(:d, arp_scale).tick, arp_scale).choose, amp: 0.1
      sleep notes.choose
    end
  end
  
end

def refresh_ambient_settings
  settings = {
    bars_change: 8,
    notes: time_cycle(cycle: :hour,
                      cycle_length: 0.5,
                      step: :minute,
                      step_length: 1,
                      max: 4,
                      min: 0,
                      round: true
                      ),
    rythm_seed: time_cycle(cycle: :hour,
                           cycle_length: 1,
                           step: :minute,
                           step_length: 1,
                           max: 65535,
                           min: 0,
                           round: false
                           ),
    scale: time_cycle(cycle: :day,
                      cycle_length: 1,
                      step: :minute,
                      step_length: 15,
                      max: $scales.length - 1,
                      min: 0,
                      round: true
                      )
  }
  
  
  
  return settings
end

def refresh_arpeggio_settings
  settings = {
    bars_change: 1,
    notes: time_cycle(cycle: :hour,
                      cycle_length: 1,
                      step: :minute,
                      step_length: 1,
                      max: 8,
                      min: 0,
                      round: true
                      ),
    rythm_seed: time_cycle(cycle: :hour,
                           cycle_length: 1,
                           step: :minute,
                           step_length: 5,
                           max: 65535,
                           min: 0,
                           round: false
                           ),
    scale: time_cycle(cycle: :hour,
                      cycle_length: 1,
                      step: :minute,
                      step_length: 1,
                      max: $scales.length - 1,
                      min: 0,
                      round: true
                      )
  }
  
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
    notes: time_cycle(cycle: :hour,
                      cycle_length: 0.25,
                      step: :minute,
                      step_length: 1,
                      max: 8,
                      min: 0,
                      round: true,
                      circle: true
                      ),
    rythm_seed: time_cycle(cycle: :hour,
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
