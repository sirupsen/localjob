class WalrusJob < Struct.new(:action)
  def perform
    "Nice try, but there's no way I'll #{action}.."
  end
end

class AngryWalrusJob < Struct.new(:angryness)
  def perform
    raise "I am this angry: #{angryness}"
  end
end
