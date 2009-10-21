module DataMapper
  module Types
    module Imap
      module NetIMAPAddressType
        def self.load(value, property)
          typecast(value, property)
        end
        
        def self.dump(value, property)
          typecast(value, property)
        end
        
        def self.typecast(value, property)
          if value.nil? || value.empty?
            []
          else
            # TODO: don't just test the first element of the array
            if value.is_a?(Array) && value.first.is_a?(Net::IMAP::Address)
              value
            else
              value = [value].flatten
              
              value.map do |val|
              
                if val =~ /<.*>$/
                  matches = val.match(/(.*)<(.*)@(.*)>/)
                  if matches
                    n = Net::IMAP::Address.new
                    n.name = matches[0].strip
                    n.mailbox = matches[1].strip
                    n.host = matches[2].strip
                    n
                  else
                    nil
                  end#matches
                else
                  matches = val.split "@"
                  if matches
                    n = Net::IMAP::Address.new
                    n.mailbox = matches[0].strip
                    n.host = matches[1].strip
                    n
                  else
                    nil
                  end#matches
                end#val =~
                
              end.compact #end of each
            end#value.is_a?
          end#if value.nil?
        end#self.typecast
      end#Net::
    end#Imap
  end#Types
end#DataMapper

module DataMapper
  module Types
    
    module Imap
      
      class ImapType < DataMapper::Type
        class << self
          attr_reader :query_details, :envelope_name, :attr_name, :method_name
          
          def imap_query(name)
            @query_details = name
          end
          
          def envelope(name)
            attr "ENVELOPE"
            @envelope_name = name
          end
          
          def envelope?
            !!@envelope_name
          end
          
          def attr(name)
            meth :attr
            @attr_name = name
          end
          
          def meth(name)
            @method_name = name
          end
          
          def attr?
            !!@attr_name
          end
        end
      end#ImapType
      
      class Sequence < ImapType
        primitive Integer
        meth :seqno
      end
      
      class Uid < ImapType
        primitive Integer
        serial true
        min 1
        attr "UID"
        imap_query(:eql => ["UID"], :like => ["UID"])
      end
      UID = Uid
      
      class BodyText < ImapType
        primitive String
        attr "RFC822.TEXT"
        imap_query(:eql => ["BODY"], :like => ["BODY"])
      end
      
      class Body < ImapType
        primitive String
        attr "RFC822"
        imap_query(:eql => ["RFC822"], :like => ["RFC822"])
      end
      
      class InternalDate < ImapType
        primitive DateTime
        attr "INTERNALDATE"
        imap_query(:lt => ["BEFORE"], :eql => ["ON"], :gt => ["SINCE"])
      end

      class EnvelopeDate < ImapType
        primitive DateTime
        envelope :date
        imap_query(:lt => ["SENTBEFORE"], :eql => ["SENTON"], :gt => ["SENTSINCE"])
      end

      class Size < ImapType
        primitive Integer
        attr "RFC822.SIZE"
        imap_query(:lt => ["SMALLER"], :gt => ["LARGER"])
      end

      class Header < ImapType
        primitive String
        attr "RFC822.HEADER"
        imap_query(:eql => ["HEADER"])
      end
      
      class From < ImapType
        primitive ::Object
        envelope :from
        imap_query(:eql => ["FROM"], :like => ["FROM"])
        include DataMapper::Types::Imap::NetIMAPAddressType
      end
      
      class Sender < ImapType
        primitive ::Object
        envelope :sender
        imap_query(:eql => ["HEADER", "Sender"], :like => ["HEADER", "Sender"])
        include DataMapper::Types::Imap::NetIMAPAddressType
      end
      
      class ReplyTo < ImapType
        primitive ::Object
        envelope :reply_to
        imap_query(:eql => ["HEADER", "Reply-To"], :like => ["HEADER", "Reply-To"])
        include DataMapper::Types::Imap::NetIMAPAddressType
      end
      
      class Cc < ImapType
        primitive ::Object
        envelope :cc
        imap_query(:eql => ["CC"], :like => ["CC"])
        include DataMapper::Types::Imap::NetIMAPAddressType
      end
      CC = Cc
      
      class To < ImapType
        primitive ::Object
        envelope :to
        imap_query(:eql => ["TO"], :like => ["TO"])
        include DataMapper::Types::Imap::NetIMAPAddressType
      end
      
      class Bcc < ImapType
        primitive ::Object
        envelope :bcc
        imap_query(:eql => ["BCC"], :like => ["BCC"])
        include DataMapper::Types::Imap::NetIMAPAddressType
      end
      BCC = Bcc
      
      class Subject < ImapType
        primitive String
        envelope :subject
        imap_query(:eql => ["SUBJECT"], :like => ["SUBJECT"])
      end
      
      class InReplyTo < ImapType
        primitive String
        envelope :in_reply_to
        imap_query(:eql => ["HEADER", "In-Reply-To"], :like => ["HEADER", "In-Reply-To"])
      end
      
      class MessageId < ImapType
        primitive String
        envelope :message_id
        imap_query(:eql => ["HEADER", "Message-ID"], :like => ["HEADER", "Message-ID"])
      end
      
    end#Imap
    
  end#Types
end#DataMapper