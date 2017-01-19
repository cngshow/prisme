module InterestingColumnCompare
  #note, these active record objects are mutable.  Use in hashes with caution (might need to consider using default hash (immutable across primary key))
  def hash
    interesting_setup
    result = 17
    @interesting_columns.each do |column|
      result = 31*result + self.send(column.to_sym).hash
    end
    result
  end

  def eql?(other)
    interesting_setup
   # $log.always("in eql! --: #{@interesting_columns}")
    result = true
    begin
      @interesting_columns.each do |column|
    #    $log.always("Column is #{column}, self.send(column.to_sym) =  #{self.send(column.to_sym)} : other.send(column.to_sym) = #{other.send(column.to_sym)}")
    #    $log.always("EQL? #{(self.send(column.to_sym).eql?(other.send(column.to_sym)))}")
        result = result && (self.send(column.to_sym).eql?(other.send(column.to_sym)))
      end
    rescue
      return false
    end
    result
  end

  protected
  def interesting_setup
      @interesting_columns ||= self.class.column_names.clone
      @interesting_columns.delete('updated_at')
      @interesting_columns.delete('created_at')
  end
end