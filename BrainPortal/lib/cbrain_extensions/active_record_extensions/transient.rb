
#
# CBRAIN Project
#
# Copyright (C) 2008-2012
# The Royal Institution for the Advancement of Learning
# McGill University
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

module CBRAINExtensions #:nodoc:
  module ActiveRecordExtensions #:nodoc:

    # ActiveRecord added behavior to make records transient and prevent saving
    # them to persistent storage (DB)
    module Transient

      Revision_info=CbrainFileRevision[__FILE__] #:nodoc:

      # Save-like methods that commit the record to persistent storage.
      SAVE_METHODS = [ :save, :save!, :update_attribute, :update_attributes, :update_attributes! ]

      # Mark the record as transient and void all save-like methods. To avoid
      # special paths for transient records, save operations always behave as
      # if they succeeded while having no effect unless +raise_on_save+ is true
      def transient!(raise_on_save = false)
        SAVE_METHODS.each do |m|
          define_singleton_method(m) do |*args|
            if raise_on_save
              cb_error "Internal error: attempt to invoke method '#{m}' on a transient record"
            else
              true
            end
          end
        end
      end

    end
  end
end
