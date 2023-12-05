
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Targets_Species_Community

<!-- badges: start -->
<!-- badges: end -->

The goal of Targets_Species_Community is to recreate the community
generated but using the targets r package

There were 11 warnings (use warnings() to see them)

``` {mermaid}
graph LR
  style Legend fill:#FFFFFF00,stroke:#000000;
  style Graph fill:#FFFFFF00,stroke:#000000;
  subgraph Legend
    direction LR
    x7420bd9270f8d27d([""Up to date""]):::uptodate --- x70a5fa6bea6f298d[""Pattern""]:::none
    x70a5fa6bea6f298d[""Pattern""]:::none --- xbf4603d6c2c2ad6b([""Stem""]):::none
  end
  subgraph Graph
    direction LR
    xfab3ac936a7a6fb3(["LandUseTiff"]):::uptodate --> x396b2293fc94c21d["Species_LU_BG"]:::uptodate
    x7432d1b8319f3fc8(["Presence_Filtered"]):::uptodate --> x396b2293fc94c21d["Species_LU_BG"]:::uptodate
    x2c4756a07e61e40e["Spp_LU_Both"]:::uptodate --> x54460dbf2d0d1aab["ModelAndPredict"]:::uptodate
    x7ced752a37ed4412(["Only_Plants"]):::uptodate --> x1234c39602c1f6ea["Presences"]:::uptodate
    xfab3ac936a7a6fb3(["LandUseTiff"]):::uptodate --> x98f93f6ded03a2de["Species_LU_Pres"]:::uptodate
    x7432d1b8319f3fc8(["Presence_Filtered"]):::uptodate --> x98f93f6ded03a2de["Species_LU_Pres"]:::uptodate
    x1234c39602c1f6ea["Presences"]:::uptodate --> x656bd6b4556eb72d(["Joint_Presences"]):::uptodate
    x54460dbf2d0d1aab["ModelAndPredict"]:::uptodate --> xbe15f87624992817(["LookUpTable"]):::uptodate
    xa7956357d7f8182e["Thresholds"]:::uptodate --> xbe15f87624992817(["LookUpTable"]):::uptodate
    xb7119b48552d1da3(["data"]):::uptodate --> x76752fc0bd503faf(["Clean"]):::uptodate
    x54460dbf2d0d1aab["ModelAndPredict"]:::uptodate --> xa7956357d7f8182e["Thresholds"]:::uptodate
    x2c4756a07e61e40e["Spp_LU_Both"]:::uptodate --> xa7956357d7f8182e["Thresholds"]:::uptodate
    x98f93f6ded03a2de["Species_LU_Pres"]:::uptodate --> x85ae53fdc9a7a960["Fixed_LU_Pres"]:::uptodate
    x396b2293fc94c21d["Species_LU_BG"]:::uptodate --> xa2609b2515af696a["Fixed_LU_BG"]:::uptodate
    xba73f251f5f433b4(["Presence_summary"]):::uptodate --> x3c37d5508d48686b(["Filtered_Species"]):::uptodate
    x76752fc0bd503faf(["Clean"]):::uptodate --> x7ced752a37ed4412(["Only_Plants"]):::uptodate
    x656bd6b4556eb72d(["Joint_Presences"]):::uptodate --> xba73f251f5f433b4(["Presence_summary"]):::uptodate
    xa2609b2515af696a["Fixed_LU_BG"]:::uptodate --> x2c4756a07e61e40e["Spp_LU_Both"]:::uptodate
    x85ae53fdc9a7a960["Fixed_LU_Pres"]:::uptodate --> x2c4756a07e61e40e["Spp_LU_Both"]:::uptodate
    x6d51284275156668(["file"]):::uptodate --> xb7119b48552d1da3(["data"]):::uptodate
    x3c37d5508d48686b(["Filtered_Species"]):::uptodate --> x01fcaa42022f4a51(["Phylo_Tree"]):::uptodate
    xfab3ac936a7a6fb3(["LandUseTiff"]):::uptodate --> xc73d904d90e721c9["buffer_500"]:::uptodate
    x7432d1b8319f3fc8(["Presence_Filtered"]):::uptodate --> xc73d904d90e721c9["buffer_500"]:::uptodate
    x3c37d5508d48686b(["Filtered_Species"]):::uptodate --> x7432d1b8319f3fc8(["Presence_Filtered"]):::uptodate
    x656bd6b4556eb72d(["Joint_Presences"]):::uptodate --> x7432d1b8319f3fc8(["Presence_Filtered"]):::uptodate
  end
  classDef uptodate stroke:#000000,color:#ffffff,fill:#354823;
  classDef none stroke:#000000,color:#000000,fill:#94a4ac;
  linkStyle 0 stroke-width:0px;
  linkStyle 1 stroke-width:0px;
```
