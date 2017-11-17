require_relative "Context"

class Program
  attr_accessor :main_context, :current_context, :quadruples, :past_context

  def initialize()
    @main_context = Context.new('GLOBAL')
    @current_context = @main_context
    @quadruples = []
  end

  def reset_context()
    # puts "\n** FUNCTION #{@current_context.name} **\n"
    # @current_context.print_tables()
    @current_context = @past_context
  end

  def reset_class_context()
    puts "\n** CLASS #{@current_context.name} **\n"
    @current_context.print_tables()
    @current_context = @main_context
  end

   def add_class(name, inherits_of)
    @current_context.classes_directory.register(name, inherits_of, Context.new("#{name} context", "class"))
    @current_context = @current_context.classes_directory.classes[name].context
  end

  def inherits_class_context(parent_class)
    parent_context = @main_context.classes_directory.classes[parent_class].context
    @current_context.functions_directory = parent_context.functions_directory.clone
    @current_context.variables_directory = parent_context.variables_directory.clone
  end

  def add_function(header, parameters, return_type)
    @current_context.functions_directory.register(header, parameters, return_type, @quadruples.count + 1)
    params = @current_context.functions_directory.functions[header].parameters
    @past_context = @current_context
    @current_context = Context.new("#{header} context", "function")
    params.each do | param |
      @current_context.variables_directory.register(param.name, param.type)
    end
  end

  def add_variable(name, type)
    @current_context.variables_directory.register(name, type)
  end

  def add_dim_variable(name, type, is_dim)
    add_variable(name, type)
    @current_context.variables_directory.variables[name].is_dim = is_dim
  end

  def add_quadruples(quad)
    @quadruples.push(quad)
  end

  def print_quadruples()
    puts "\n\n** GLOBAL Context **\n\n"
    @main_context.print_tables()
    puts "\n============== START QUADS =============="
    @quadruples.each_with_index do |quad, index|
      puts "#{index}: #{quad.operator}, #{quad.left_side}, #{quad.right_side}, #{quad.result}"
    end
    puts "\n============== END QUADS =============="
  end
end
