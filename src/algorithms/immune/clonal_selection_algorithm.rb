# Clonal Selection Algorithm (CLONALG) in the Ruby Programming Language

# The Clever Algorithms Project: http://www.CleverAlgorithms.com
# (c) Copyright 2010 Jason Brownlee. Some Rights Reserved. 
# This work is licensed under a Creative Commons Attribution-Noncommercial-Share Alike 2.5 Australia License.

def objective_function(vector)
  return vector.inject(0.0) {|sum, x| sum + (x**2.0)}
end

def decode(bitstring, search_space, bits_per_param)
  vector = []
  search_space.each_with_index do |bounds, i|
    off, sum, j = i*bits_per_param, 0.0, 0    
    bitstring[off...(off+bits_per_param)].reverse.each_char do |c|
      sum += ((c=='1') ? 1.0 : 0.0) * (2.0 ** j.to_f)
      j += 1
    end
    min, max = bounds
    vector << min + ((max-min)/((2.0**bits_per_param.to_f)-1.0)) * sum
  end
  return vector
end

def evaluate(pop, search_space, bits_per_param)
  pop.each do |p|
    p[:vector] = decode(p[:bitstring], search_space, bits_per_param)
    p[:cost] = objective_function(p[:vector])
  end
end

def random_bitstring(num_bits)
  return (0...num_bits).inject(""){|s,i| s<<((rand<0.5) ? "1" : "0")}
end

def point_mutation(bitstring, rate=1.0/bitstring.size)
  child = ""
   bitstring.size.times do |i|
     bit = bitstring[i].chr
     child << ((rand()<rate) ? ((bit=='1') ? "0" : "1") : bit)
  end
  return child
end

def affinity_proportionate_mutation(cost, mutate_rate)
  cost = cost * -1.0 if cost<0
  return Math.exp(-2.5 * cost)
end

def num_clones(pop_size, clone_factor)
  return (pop_size * clone_factor).to_i
end

def calculate_affinity(pop)
  max = pop.max{|x,y| x[:cost]<=>y[:cost]} 
  min = pop.min{|x,y| x[:cost]<=>y[:cost]}
  range = max[:cost]-min[:cost]
  if range == 0
    pop.each {|p| p[:affinity] = 1.0}
  else
    pop.each {|p| p[:affinity] = 1.0-(p[:cost]-min[:cost]/range)}
  end
end

def clone_and_hypermutate(pop, clone_factor, mutate_factor)
  clones = []
  num_clones = num_clones(pop.size, clone_factor)
  calculate_affinity(pop)
  pop.each do |antibody|
    p_mutation = affinity_proportionate_mutation(antibody[:affinity], mutate_factor)
    num_clones.times do 
      clone = {}
      clone[:bitstring] = ""+antibody[:bitstring]
      point_mutation(clone[:bitstring], p_mutation)
      clones << clone
    end
  end
  return clones  
end

def greedy_merge(pop, clones)
  union = pop + clones
  union.sort!{|x,y| x[:cost]<=>y[:cost]}
  return union[0...pop.size]
end

def random_insertion(search_space, pop, num_rand, bits_per_param)
  return pop if num_rand == 0
  rands = Array.new(num_rand) do |i|
    {:bitstring=>random_bitstring(search_space.size*bits_per_param)}
  end
  evaluate(rands, search_space, bits_per_param)
  return greedy_merge(pop, rands)
end

def search(search_space, max_gens, pop_size, clone_factor, mutate_factor, num_rand, bits_per_param=16)
  pop = Array.new(pop_size) do |i|
    {:bitstring=>random_bitstring(search_space.size*bits_per_param)}
  end
  evaluate(pop, search_space, bits_per_param)
  best = pop.min{|x,y| x[:cost]<=>y[:cost]}
  max_gens.times do |gen|
    clones = clone_and_hypermutate(pop, clone_factor, mutate_factor)
    evaluate(clones, search_space, bits_per_param)
    pop = greedy_merge(pop, clones)    
    pop = random_insertion(search_space, pop, num_rand, bits_per_param)
    best = (pop + [best]).min{|x,y| x[:cost]<=>y[:cost]}
    puts " > gen #{gen+1}, f=#{best[:cost]}, a=#{best[:affinity]} s=#{best[:vector].inspect}"
  end  
  return best
end

if __FILE__ == $0
  # problem configuration
  problem_size = 2
  search_space = Array.new(problem_size) {|i| [-5, +5]}
  # algorithm configuration
  max_gens = 100
  pop_size = 100
  clone_factor = 0.1
  mutate_factor = 2.5
  num_rand = 2
  # execute the algorithm
  best = search(search_space, max_gens, pop_size, clone_factor, mutate_factor, num_rand)
  puts "done! Solution: f=#{best[:cost]}, s=#{best[:vector].inspect}"
end
