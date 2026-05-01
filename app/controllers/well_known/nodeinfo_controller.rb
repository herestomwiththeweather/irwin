class WellKnown::NodeinfoController < ApplicationController
  def index
    render json: {"links": links}, status: 200
  end

  def show
    render json: { version: '2.0',
                   software: software,
                   usage: { users: users },
                   openRegistrations: global_prefs.enable_registrations,
                   protocols: protocols }, status: 200
  end

  private

  def software
    { name: 'irwin', version: Irwin::Version.to_s }
  end

  def users
    { total: User.count, activeMonth: User.active_month, activeHalfyear: User.active_halfyear }
  end

  def protocols
    [ 'activitypub', 'indieauth' ]
  end

  def links
    [{ rel: 'http://nodeinfo.diaspora.software/ns/schema/2.0', href: nodeinfo_schema_url }]
  end
end
