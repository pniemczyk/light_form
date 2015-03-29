def class_factory(opts = {}, &block)
  Class.new(described_class).tap do |klass|
    klass.class_eval(&block) if block_given?
    Object.const_set(opts[:real_class_name], klass)     if opts[:real_class_name]
    klass.class_eval("def self.name; \"#{name}\"; end") if opts[:name]
  end
end

def object_factory(opts = {}, &block)
  class_factory(opts, &block).new(opts.fetch(:attributes, {}))
end
