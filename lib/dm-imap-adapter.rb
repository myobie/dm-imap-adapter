require 'dm-core'
require 'net/imap'
require 'lib/dm-imap-adapter/net_imap_ext'
require 'lib/dm-imap-adapter/types'

### Hack for frozen object problem

module DataMapper
  module Resource
    def original_attributes
      @original_attributes || {} # Fix for frozen crap
    end
  end
end

###

module DataMapper
  module Adapters
    
    class ImapAdapter < AbstractAdapter
      
      def create(resources)
        resources.map do |resource|
          with_connection(resource.model) do |connection|
            
            last_email = connection.uid_fetch(-1, "UID")
            if last_email
              next_uid = last_email.first.attr[:UID].to_i
            else
              next_uid = 1
            end
            
            initialize_serial(resource, next_uid)
            
#             email_text = <<EOT.gsub(/\n/, "\r\n")
# Subject: #{resource.subject}
# From: #{resource.from}
# To: #{resource.to}
# 
# #{resource.body}
# EOT
#             
            email_text = ""
            
            email_text << "Subject: #{resource.subject}\n" if resource.respond_to?(:subject)
            email_text << "From: #{resource.from}\n" if resource.respond_to?(:from)
            email_text << "To: #{resource.to}\n" if resource.respond_to?(:to)
            email_text << "\n#{resource.body}" if resource.respond_to?(:body)
            
            email_text = email_text.gsub(/\n/, "\r\n")
            
            if resource.respond_to?(:date)
              date = resource.date
            else
              date = Time.now
            end
            
            if resource.respond_to?(:flags)
              flags = resources.flags
            else
              flags = []
            end
            
            connection.append(@options[:path].gsub(%r{^/}, ""), email_text, flags, date)
            
          end
        end.size
      end
      
      def read(query)
        with_connection(query.model) do |connection|
          
          attr_props = query.model.properties.select { |prop| prop.type.attr? }
          attrs = attr_props.collect { |prop| prop.type.attr_name }.compact.uniq
          
          # TODO: don't do 1..-1, but instead do a search and then fetch the uids returned
          uids = 1..-1
          
          # if query.conditions
          #   query_array = []
          #   debugger
          #   query.conditions.each do |op, property, value|
          #     query_array += (property.type.query_details[op] + [value])
          #   end
          #   uids = connection.uid_search(query_array)
          # else
          #   uids = 1..-1
          # end
          
          mails = connection.uid_fetch(uids, attrs) || []
          
          results = materialize_records_for(query.model, mails)
          query.filter_records(results.dup)
          # results.dup
          
        end#with_connection
      end#read

      def update(attributes, collection)
        raise NotImplemented
      end

      def delete(collection)
        with_connection(collection.query.model) do |connection|
          connection.uid_store(collection.collect { |record| record.uid }, "+FLAGS", [:Deleted])
          connection.expunge
        end
      end

      private

      def initialize(name, options = {})
        super
        # @connection = create_connection
      end
      
    protected
      def create_connection(model)
        args = [@options[:host], @options[:port], @options[:ssl]].compact
        imap = Net::IMAP.new(*args)
        begin
          imap.authenticate "login"
        rescue
        ensure
          imap.login(@options[:user], @options[:password])
        end
        mailbox = @options[:path].gsub(%r{^/}, "")
        imap.select(mailbox) rescue raise("Mailbox #{mailbox} not found")
        imap
      end
      
      def with_connection(model)
        begin
          connection = create_connection(model)
          return yield(connection)
        rescue => error
          DataMapper.logger.error(error.to_s)
          raise error
        ensure
          close_connection(connection) if connection
        end
      end
      
      def close_connection(connection)
        connection.disconnect
      end
      
      def materialize_records_for(model, mails)
        # Array
        mails.collect do |mail|
          # of Hashes (one hash per loop)
          model.properties.inject({}) do |hash, prop|
            hash[prop.field] = mail.send(prop.type.method_name.to_sym)
            
            if prop.type.attr?
              hash[prop.field] = hash[prop.field][prop.type.attr_name]
            end#if
            
            if prop.type.envelope?
              hash[prop.field] = hash[prop.field][prop.type.envelope_name]
            end
            
            hash
          end#inject
        end#collect
      end#materialize_records_for
      
    end#ImapAdapter
    
    const_added(:ImapAdapter)
    
  end#Adapters
end#DataMapper