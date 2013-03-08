#!/usr/bin/env ruby
###############################################################################
# Quick State Prediction 0.1.0 beta by Chase Higgins
###############################################################################
# Accept polling average and intrade odds from command line for quick state
# prediction to build electoral maps
###############################################################################

class State 
  def initialize(poll_avg, intrade_odds) 
    @poll_avg = poll_avg;
    @intrade_odds = intrade_odds;
  end; # end of constructor method

  def weighIntrade()

  end; # end of weighIntrade method

  def weightPolls()

  end; # end of weighPolls method

  def determineWinner() 

  end; # end of determineWinner method
 
  def showResults() 

  end; # end of showResults method

end; # end of State class

def main()
  intrade = ARGV[0].dup;
  polling = ARGV[1].dup;
  lead = Lead.new(polling, intrade);
end;

if (__FILE__ == $0) 
  main;
end;
