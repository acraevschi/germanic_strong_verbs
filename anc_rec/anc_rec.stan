functions {
  matrix[] fill_matrix(vector beta, int J) {
    matrix[J,J] Q[2]; // 2 stands for number of states for TAM
    // beta[1:20] is the no matrix and beta[21:40] is the yes matrix
    vector[2*(J-1)*(J-2)] mu = beta[1:(2*(J-1)*(J-2))];
    real log_death_rate = beta[(2*(J-1)*(J-2))+1];
    for (i in 1:2){
      Q[i,,] = rep_matrix(0, J, J);
    }
    {
      int k = 1;
      for (n in 1:2){
        for (i in 1:(J-1)) {
          for (j in 1:(J-1)) {
            if (i != j) {
              Q[n,i,j] = beta[k];
              k += 1;
            }
          }
        }
      }
    }
    for (n in 1:2){
      for (i in 1:(J-1)) {
        Q[n,J,i] = 1e-50;
        Q[n,i,J] = log_death_rate;
      }
      for (i in 1:J) {
        Q[n,i,i] = -sum(Q[n,i,]);
      }
    }
    return Q;
  }
  //compute likelihood via Felsenstein's Pruning Algorithm
  int pruning_rng( vector beta , real[] xr , int[] xi ) {
    int N = xi[1];
    int B = xi[2];
    int J = xi[3];
    real brlen[B] = xr;
    // need to correct the block below
    int child[B] = xi[4:(B+3)];
    int parent[B] = xi[(4+B):(2*B+3)];
    int segment_states[B] = xi[(2*B+4):(3*B+3)];
    int tiplik[N*J] = xi[(3*B+4):(3*B+3)+J*N];
    vector[2*(J-1)*(J-2)+1] rates = exp(beta);
    matrix[N,J] lambda;
    vector[J] root_norm;
    int z;
    matrix[J,J] Q[2] = fill_matrix(rates, J); // here it's fine
    for (j in 1:J) {
      lambda[,j] = to_vector(log(tiplik[((N*j)-(N-1)):(N*j)]));
    }
    for (b in 1:B) {
      // the matrix exp part should be fine
      matrix[J,J] P = matrix_exp(Q[segment_states[b],,]*brlen[b]); //via matrix exponentiation
      for (d in 1:J) {
        lambda[parent[b],d] += log(
          dot_product(
            P[d],
            exp(lambda[child[b]])
            )
          );
      }
    }
    root_norm = to_vector(lambda[parent[B],]);
    root_norm = exp(root_norm - log_sum_exp(root_norm));
    z = categorical_rng(root_norm);
    return(z);
  }
}
data {
  int<lower=1> N; //number of tips+internal nodes+root
  int<lower=1> T; //number of tips
  int<lower=1> B; //number of branches
  int<lower=1> J; //number of states
  int<lower=1> S; //number of characters
  int<lower=1> segment_states[B]; // TAM state of each branch
  int<lower=1> child[B];                //child of each branch
  int<lower=1> parent[B];               //parent of each branch
  real<lower=0> brlen[B];                //length of each branch
  int<lower=0,upper=1> tiplik[S,N,J];     //likelihoods for data at tips in tree
  vector[2*(J-1)*(J-2)] mu;
  real log_death_rate;
}
// double check how to pack the data given new entries
transformed data {
  //pack phylogenetic data into S 1-dim vectors
  vector[0] theta[S]; //empty local params
  int xi[S,3+3*B+N*J];
  real xr[S,B];
  vector[2*(J-1)*(J-2)+1] beta;
  for (i in 1:S) {
    xr[i] = to_array_1d(brlen);
    xi[i,1] = N;
    xi[i,2] = B;
    xi[i,3] = J;
    xi[i,4:(B+3)] = child;
    xi[i,(B+4):(2*B+3)] = parent;
    xi[i,(2*B+4):(3*B+3)] = segment_states;
    for (j in 1:J) {
      xi[i,(3*B+4)+(j-1)*N:(3*B+3)+j*N] = tiplik[i,,j];
    }
    xi[i] = to_array_1d(xi[i]);
  }
  beta[1:(2*(J-1)*(J-2))] = mu;
  beta[2*(J-1)*(J-2)+1] = log_death_rate;
}
generated quantities {
  int z[S];
  for (d in 1:S) {
    z[d] = pruning_rng(beta,xr[d],xi[d]);
  }
}
