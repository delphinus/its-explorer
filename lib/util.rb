module Util
  def command?(name)
    `which #{name}`
    $?.success?
  end
end
