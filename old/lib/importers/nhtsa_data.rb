module NhtsaData
  def self.import_from_tab_delimited_feed(url)
    begin
      file = Tempfile.new("nhtsa")
      file.write(Net::HTTP.get(URI(url)))
      file.close

      File.open(file.path).each do |line|
        row = []
        line.split("\t").each { |field| row << field.chomp }
        import_row(row)
      end
    rescue Exception => e
      Rails.logger.error(e.message)
    end
  end

  private

  def self.import_row(row)
    Recall.transaction do
      recall = Recall.where(organization: 'NHTSA',
                            recall_number: row[1]).first_or_initialize do |r|
        r.recalled_on = row[24].blank? ? row[16] : row[24]
      end

      if recall.recall_details.empty?
        Recall::NHTSA_DETAIL_FIELDS.each_pair do |detail_type, column_index|
          next if row[column_index].blank?
          rd = recall.recall_details.build(detail_type: detail_type,
                                           detail_value: row[column_index])
          recall.recall_details << rd
        end
      end

      recall.auto_recalls << recall.auto_recalls.where(recalled_component_id: row[23]).
          first_or_initialize do |ar|
        ar.make = row[2]
        ar.model = row[3]
        ar.year = row[4] == '9999' ? nil : row[4].to_i
        ar.component_description = row[6]
        ar.manufacturer = row[14]
        ar.manufacturing_begin_date = row[8].blank? ? nil : Date.parse(row[8])
        ar.manufacturing_end_date = row[9].blank? ? nil : Date.parse(row[9])
      end

      recall.save!
    end
  end
end