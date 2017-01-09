class VaSite < ActiveRecord::Base
  validates_uniqueness_of :va_site_id
  self.primary_key = 'va_site_id'
  INTERESTING_COLUMNS = VaSite.column_names.clone
  INTERESTING_COLUMNS.delete('updated_at')
  INTERESTING_COLUMNS.delete('created_at')

  #note, these active record objects are mutable.  Use in hashes with caution
  def hash
    result = 17
    INTERESTING_COLUMNS.each do |column|
      result = 31*result + self.send(column.to_sym).hash
    end
    result
  end

  def eql?(other)
    result = true
    begin
      INTERESTING_COLUMNS.each do |column|
        result = result && (self.send(column.to_sym).eql?(other.send(column.to_sym)))
      end
    rescue
      return false
    end
    result
  end

end

#load('./app/models/va_site.rb')