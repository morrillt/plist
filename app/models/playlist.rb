class Playlist < ActiveRecord::Base
  extend FriendlyId
  include Playlister::Social
  include Playlister::Video

  friendly_id :title, :use => :slugged
  delegate :username, :to => :user

  has_many :messages, :order => 'created_at DESC', :limit => 20
  has_many :videos, :order => 'sort ASC'
  has_many :members, :through => :collaborators, :source => :user
  belongs_to :user
  has_many :onlines
  has_many :online_users, through: :onlines, :source => :user

  scope :featured, where(:featured => true)
  scope :common, where(:featured => false)
  scope :published, where(:published => true)
  scope :drafts, where(:published => false)
  scope :recent, lambda {|n| order_by("created_at DESC").limit(n) }

  def update_thumb
    self.thumb = Youtube.get_thumbnail_url(videos.first.ytid) if videos.count > 0
    save
  end
end