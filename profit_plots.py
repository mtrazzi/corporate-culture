import numpy as np
import matplotlib.pyplot as plt

def profit(e_j):
    def pi(e_i):
        return np.sqrt(e_i + e_j) - e_i ** 2
    return pi

def main():
    x = np.linspace(0.0001, 1, 1000)
    e_i_max = []
    e_j_values = np.linspace(0.0001, 1.0001, 100)
    for e_j in e_j_values:
        pi = profit(e_j)
        #plt.plot(x, pi(x), label=str(e_j))
        ind = np.argmax(pi(x))
        e_i_max.append(x[ind])
        print("argmax for e_j={}: e_i={}".format(e_j,x[ind]))
    plt.plot(e_j_values, e_i_max)
    plt.plot(e_j_values, e_j_values)
    plt.legend()
    plt.show()

if __name__ == '__main__':
    main()