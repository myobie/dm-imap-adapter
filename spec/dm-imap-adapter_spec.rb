require File.dirname(__FILE__) + '/spec_helper'

class LocalInbox
  include DataMapper::Resource
  include DataMapper::Types::Imap
  
  def self.default_repository_name
    :test_inbox
  end

  property :uid, UID, :key => true
  property :message_id, MessageId
  property :subject, Subject
  property :sender, Sender
  property :from, From
  property :to, To
  property :body, BodyText
  property :raw_body, Body
  property :date, InternalDate
  property :envelope_date, EnvelopeDate
  property :size, Size
  property :sequence, Sequence
end

describe DataMapper::Adapters::ImapAdapter do
  
  before do
    LocalInbox.all.map { |l| l.destroy }

    LocalInbox.create :to => "test@localhost",
                      :from => "Me <me@example.com>",
                      :subject => "Test email 1",
                      :body => "Hello there, how are you?"

    LocalInbox.create :to => "test@localhost",
                      :from => "me@example.com",
                      :subject => "Test email 2 boo ya",
                      :body => "Hi,\n\nTest."
                      
    LocalInbox.create :to => "test@localhost",
                      :from => "Me <me@example.com>",
                      :subject => "Test email 3",
                      :body => "Hello there."

    LocalInbox.create :to => "test@localhost",
                      :from => "me@example.com",
                      :subject => "Test email 4 rabbit",
                      :body => "Hi,\n\nHow's it going?\n\nGive us a call.\n\nTest."
  end
  
  should "successfully connect to the local imap server" do
    lambda { LocalInbox.all }.should.not.raise
  end
  
  should "have two emails in the inbox" do
    LocalInbox.all.length.should == 4
  end
  
  should "know who sent the email" do
    LocalInbox.first.from.first.name.should == "Me"
    LocalInbox.first.from.first.email.should == "me@example.com"
    LocalInbox.first.from.first.to_s.should == "Me <me@example.com>"
  end
  
  should "know how the email was sent to" do
    LocalInbox.first.to.first.to_s.should == "<test@localhost>"
  end
  
  should "create a new email" do
    lambda { 
      LocalInbox.create(:to => "test", :from => "test", :subject => "Test", :body => "Test")
    }.should.increase { LocalInbox.all.length }
  end
  
  should "destroy an email" do
    lambda { LocalInbox.first.destroy }.should.decrease { LocalInbox.all.length }
  end
  
  should "find the email with the subject containing 'rabbit'" do
    LocalInbox.first(:subject.like => "rabbit").subject.should == "Test email 4 rabbit"
  end
  
end
