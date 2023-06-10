{ self, ... }: {
  kernel.python.paper = {
    enable = true;
#    nixpkgs = self.inputs.nixpkgs-stable;
    extraPackages = ps: with ps; [ numpy scipy matplotlib seaborn pandas ];
#    extraPackages = ps: with ps; [ numpy ipython jupyter seaborn pandas numpy matplotlib ];
  };
}
