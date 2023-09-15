/xmatch[ ]*EQU/I d
/if[ ]*xmatch/I , /endif/I d
/if[ ]*NOT[ ]*xmatch/I , /endif/I { /if[ ]*NOT[ ]*xmatch/I d
                                    /endif/I d
                                  }
                
