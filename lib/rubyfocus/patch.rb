# The patch class represents a text-file patch, storing update, delete, and creation operations.
# It should also be able to apply itself to an existing document.
class Rubyfocus::Patch
	# The fetcher this patch belongs to. We mainly use this to work out how to fetch content for the patch proper
	attr_accessor :fetcher

	# Operations to be performed on a document
	attr_accessor :update, :delete, :create

	# The file the patch loads from
	attr_accessor :file

	# These record the transformation in terms of patch ID values.
	attr_accessor :from_ids, :to_id

	# The time the file was submitted
	attr_accessor :time

	# By default we initialize patches from a file. To initialize from a string, use the .from_string method.
	# This class will lazily load data from the file proper
	def initialize(fetcher=nil, file=nil)
		@fetcher = fetcher
		@file = file
		@update = []
		@create = []
		@delete = []

		if file 
			if File.basename(file) =~ /^(\d+)=(.*)\./
				self.time 		= Time.parse($1)
				ids 					= $2.split("+")
				self.to_id 		= ids.pop
				self.from_ids = ids
			else
				raise ArgumentError, "Constructed patch from a malformed patch file: #{file}."
			end
		end
	end

	# Load from a string.
	def self.from_string(fetcher, str)
		n = new(fetcher)
		n.load_data(str)
		n
	end

	# Loads data from the file. Optional argument +str+ if you want to supply your own data,
	# otherwise will load file data
	def load_data(str=nil)
		return if @data_loaded
		@data_loaded = true

		str ||= fetcher.patch(self.file)
	  doc = Nokogiri::XML(str)
	  doc.root.children.select{ |n| !n.text?}.each do |child|
	  	case child["op"]
	  	when "update"
	  		@update << child
	  	when "delete"
	  		@delete << child
	  	when "reference" # Ignore!
	  	when nil
	  		@create << child
	  	else
	  		raise RuntimeError, "Rubyfocus::Patch encountered unknown operation type #{child["op"]}."
	  	end
	  end
	end

	# Update, delete and create methods
	def update; load_data; @update; end
	def delete; load_data; @delete; end
	def create; load_data; @create; end

	def to_s
		"(#{from_id} -> #{to_id})"
	end
end