#!/usr/bin/ruby
#
# This file is part of CPEE-CORRELATORS-SYNC.
#
# CPEE-CORRELATORS-SYNC is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# CPEE-CORRELATORS-SYNC is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with
# CPEE-CORRELATORS-SYNC (file LICENSE in the main directory). If not, see
# <http://www.gnu.org/licenses/>.

require 'riddl/server'
require 'riddl/client'

SyncList = Data.define(:amount, :list)

class Message < Riddl::Implementation
  def response
    syncs = @a[0]
    id = @p[0].value
    amount = @p[1].value

    syncs[id] ||= SyncList.new(amount,{})

    syncs[id].amount = amount if syncs[id].amount < amount
    if syncs[id].list.length - 1 ==  amount
      syncs[id].list.each do |cb|
        Riddl::Client.new(cb).put
      end
      syncs.delete(id)
    else
      syncs[id].list << @h['CPEE_CALLBACK']
      return RIDDL::Header.new('CPEE-CALLBACK',true)
    end
    nil
end

Riddl::Server.new(File.join(__dir__,'/sync.xml'), :host => 'localhost', :port => 9312) do |opts|
  accessible_description true
  cross_site_xhr true

  opts[:sync] = {}

  on resource do
    run Sync, opts[:sync] if post 'sync'
  end
end.loop!
