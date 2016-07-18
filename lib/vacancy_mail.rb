require 'mail-iso-2022-jp'
require 'pathname'

class VacancyMail
  PASSWORD_FILE = Pathname(__FILE__).expand_path.parent.parent + '.gmail-password'

  def self.send(body_content)
    mail = Mail.new charset: 'ISO-2022-JP' do
      from    'delphinus@remora.cx'
      to      'delphinus@remora.cx'
      subject "ITS 宿泊施設空き情報（#{Time.now.strftime '%F %T'}）"
      body    body_content
    end
    mail.delivery_method :smtp, {
      address:        'smtp.gmail.com',
      port:           587,
      domain:         'smtp.gmail.com',
      authentication: :plain,
      user_name:      'delphinus@remora.cx',
      password:       password,
    }
    mail.deliver
  end

  private

    def self.password
      begin
        PASSWORD_FILE.read.chomp
      rescue => e
        raise 'cannot load password file'
      end
    end
end
