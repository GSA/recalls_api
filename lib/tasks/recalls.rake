namespace :usagov do
  namespace :recalls do
    desc 'Load CDC food/drug recall data from RSS feed'
    task import_cdc_data: :environment do
      CdcData.import_from_rss_feed('http://www.fda.gov/AboutFDA/ContactFDA/StayInformed/RSSFeeds/Recalls/rss.xml', 'food', true)
      CdcData.import_from_rss_feed('http://www.fsis.usda.gov/RSS/usdarss.xml', 'food', true)
      CdcData.import_from_rss_feed('http://www2c.cdc.gov/podcasts/createrss.asp?c=146', 'food')
      CdcData.import_from_rss_feed('http://www.fda.gov/AboutFDA/ContactFDA/StayInformed/RSSFeeds/DrugRecalls/rss.xml', 'drug')
    end

    desc 'Load CPSC recall data from XML feed'
    task :import_cpsc_data, [:start_date, :end_date] => :environment do |t, args|
      today = Date.current.to_s(:db)
      start_on = args.start_date.present? ? args.start_date : today
      end_on = args.end_date.present? ? args.end_date : today
      params = { startDate: start_on, endDate: end_on, userId: nil, password: nil }
      url = "http://www.cpsc.gov/cgibin/CPSCUpcWS/CPSCUpcSvc.asmx/getRecallByDate?#{params.to_param}"
      CpscData.import_from_xml_feed(url)
    end

    desc 'Load NHTSA recall data from tab delimited feed'
    task import_nhtsa_data: :environment do
      url = 'http://www-odi.nhtsa.dot.gov/downloads/folders/recalls/mIBT4jvpyrRM6YJ3QIyC/flat_recalls_new.txt'
      NhtsaData.import_from_tab_delimited_feed(url)
    end
  end
end