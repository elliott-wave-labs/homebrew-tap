class PrimeCrunch < Formula
  desc "Mining spacetime for record-breaking primes"
  homepage "https://github.com/elliott-wave-labs/prime-crunch"
  url "https://github.com/elliott-wave-labs/prime-crunch/archive/refs/tags/crunch/26.04.0-1.tar.gz"
  version "26.04.0-1"
  sha256 "14310603df09623bd552811cc3cfc7d2edb0ed600247215564a75e674a109e7b"
  license "MIT"
  head "https://github.com/elliott-wave-labs/prime-crunch.git", branch: "main"

  depends_on arch: :arm64
  depends_on "gmp"
  depends_on :macos

  def install
    # The SVE transforms need -march=armv8-a+sve, which Homebrew's compiler shims strip by default.
    ENV.permit_arch_flags

    gmp = Formula["gmp"]
    cd "genefer" do
      system "make", "-f", "makefile_mac_arm", "genefer_mac_arm.tmp", "geneferg_mac_arm.tmp",
             "CC=#{ENV.cxx} -std=c++17",
             "BOINC=",
             "GMP_INC=-I#{gmp.opt_include}",
             "GMP_LIB=-L#{gmp.opt_lib} -lgmp"
      libexec.install "genefer_mac_arm.tmp" => "genefer", "geneferg_mac_arm.tmp" => "geneferg"
    end

    inreplace "crunch/prime-crunch" do |s|
      s.gsub! "@@VERSION@@", version.to_s
      s.gsub! "@@ENGINE_DIR@@", libexec.to_s
    end
    bin.install "crunch/prime-crunch"
  end

  def caveats
    <<~EOS
      Run `prime-crunch` to get started. It asks whether to connect this Mac to
      PrimeGrid through BOINC, and walks you through creating an account if you
      need one. Or test a 147,456-digit number right away:
        prime-crunch -b 1000000000 -n 14
    EOS
  end

  test do
    ENV["PRIME_CRUNCH_HOME"] = testpath
    assert_match "1534^{2^12} + 1 is a probable prime", shell_output("#{bin}/prime-crunch --cpu -b 1534 -n 12")
    assert_match "res64 = 4E43A5B93273C649", shell_output("#{bin}/prime-crunch --cpu -b 1000000000 -n 12")
  end
end
