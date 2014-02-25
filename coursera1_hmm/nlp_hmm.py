# -*- coding: utf-8 -*-
"""
Created on Wed Mar 13 21:01:44 2013

@author: kuvik
"""


import os 

if os.name == 'posix':
    bdir = '/home/kuvik/Dropbox/Computer science/Python/NLP/coursera_nlp1_hmm/'
elif os.name == 'nt':
    bdir = 'C:\Users\Mario\Dropbox\Computer science\Python\NLP\coursera_nlp1_hmm\\'



### PART 1.1 ###

def emission_mle(co, x=None, y='I-GENE'):
    """ x must be a valid word; y is 'I-GENE' or 'O' """
    
    co_y2x = {}
    co_y = 0
    co_y1 = 0
    em = {}
    
    f = open(co,'r')
    l = f.readline()
    while l:
        w = l.strip().split() 
        if w[1] == 'WORDTAG':      # for all emission counts 
            if w[2] == y:          # if tag y of emission count
                co_y2x[w[3]] = float(w[0])
        
        if w[1] == '1-GRAM':      # for the unigram counts 
            if w[2] == y:          # if tag y of unigram count
                co_y1 = float(w[0])
        
        l = f.readline()
    
    f.close()
    
    for key in co_y2x.keys():  # counting y-tags 
        co_y = co_y + co_y2x[key]  #co_y = sum(co_y2x.values()) = co_y1
    
    assert co_y1 == co_y    
    
    '''if '_RARE_' in co_y2x:
        co_y2x['_RARE_'] = 2 # because rares only appear 0, 1, 2, 3, or 4 times'''  
    
    for key in co_y2x.keys():
        em[key] = co_y2x[key] / co_y    
    
    if x == None:
        return em
    else:
        return em[x] 


# python count_freqs.py gene.train > gene.counts
tr_co = bdir+'gene.counts'
emission_mle(tr_co)



### PART 1.2 ###

def repl_infreq_w(co, fut = None, tagged = 1):
    
    rarewords = set()
    n = 5    # 2:18299; 3:,20.09; 4:,24952,20.43; 5:26155,19.67; 10:,16.33
    
    fco = open(co,'r')
    l = fco.readline()
    while l:
        w = l.strip().split()
        if int(w[0]) < n:    #maybe this was the MISTAKE? I counted only those words belonging to each tag instead of the whole sum!
            rarewords.add(w[tagged+2])
        
        l = fco.readline()
    
    fco.close()
    
    if fut != None:
        finp = open(fut[0],'r')
        fout = open(fut[1],'w')
        l = finp.readline()
        while l:
            line = l.strip()
            if line:
                w = line.split()
                if w[0] in rarewords:
                    l = l.replace(w[0] + ' ','_RARE_' + ' ')
                
                fout.write(l)
            else:
                fout.write('\n')
            
            l = finp.readline()
        
        finp.close()
        fout.close()
    
    return rarewords


tr = bdir + 'gene.train'
trr = bdir + 'gene.train.rare'

trr_co = bdir + 'gene.counts.rare'
##tr_rarewords = repl_infreq_w(tr_co, (tr, trr))    
# python count_freqs.py gene.train.rare > gene.counts.rare



### PART 1.3 ###

def simple_tagger(r_co, dev, dp1o):
    
    em_gene = emission_mle(r_co, y = 'I-GENE')
    em_O = emission_mle(r_co, y = 'O')
    etagger = {}
    al = ''
    tag = ''
    
    for key in (set(em_gene.keys()) | set(em_O.keys())):
        if key in set(em_gene.keys()) - set(em_O.keys()):
            etagger[key] = 'I-GENE'
        elif key in set(em_O.keys()) - set(em_gene.keys()):
            etagger[key] = 'O'
        else:
            if  max(em_gene[key], em_O[key]) == em_gene[key]:
                etagger[key] = 'I-GENE'
            else:
                etagger[key] = 'O'
    
    fdev = open(dev, 'r')
    fdp1o = open(dp1o, 'w')
    l = fdev.readline()
    while l:
        line = l.strip()
        if line:
            w = line
            if w in set(etagger):
                tag = etagger[w]
                '''elif w in dev_rarewords: 
                    tag = etagger['_RARE_']
                '''
            else: # unseen words 
                tag = etagger['_RARE_']
            
            al = w + ' ' + tag + '\n'
        else:
            al = '\n'
        
        fdp1o.write(al)
        l = fdev.readline()
    
    fdev.close()
    fdp1o.close()


dev = bdir + 'gene.dev'
dp1o = bdir + 'gene_dev.p1.out'
'''devr = bdir + 'gene.devr'
    dev_co = bdir + 'gene.dev_co'
    # python count_freqs.py gene.dev > gene.dev_co
    dev_rarewords = repl_infreq_w(dev_co, (dev, devr), tagged = 0)    
'''
simple_tagger(trr_co, dev, dp1o)


test = bdir + 'gene.test'
tp1o = bdir + 'gene_test.p1.out'
simple_tagger(trr_co, test, tp1o)
# python eval_gene_tagger.py gene.key gene_dev.p1.out
# Submit PART 1: python submit.py



### PART 2 ###

def transition_mle(cor, trigram = None):
    ''' trigram tuple elements in {O, I-GENE, *, STOP} '''
    
    if trigram == None:
        coal3g = {}
        coal2g = {}
        trigels = {'O', 'I-GENE', '*', 'STOP'}
        fcor = open(cor,'r')
        l = fcor.readline()
        for i in trigels:
            for j in trigels:
                for k in trigels:
                    while l:
                        w = l.strip().split()
                        if w[1] == '3-GRAM':
                            coal3g[(w[2], w[3], w[4])] = int(w[0])
                        
                        if w[1] == '2-GRAM':
                            coal2g[(w[2], w[3])] = int(w[0])
                        
                        l = fcor.readline()
        
        return {'3g': coal3g, '2g': coal2g}
    
    co_3g = 0
    co_2g = 0
    
    fcor = open(cor,'r')
    l = fcor.readline()
    
    while l:
        w = l.strip().split() 
        if w[1] == '3-GRAM' and (w[2], w[3], w[4]) == trigram:
            co_3g = int(w[0])
        
        if w[1] == '2-GRAM' and (w[2], w[3]) == trigram[:2]:
            co_2g = int(w[0])
        
        if co_3g != 0 and co_2g != 0:
            break
        
        l = fcor.readline()
    
    fcor.close()
    
    return co_3g / co_2g


def emission_r_mle(em_O, em_gene, x, y, rw = set()):
    """ y is 'I-GENE' or 'O', but never '*' """
    
    if y == '*':
        raise "'*' tag has no associated emission parameter"
    
    if x in (set(em_gene.keys()) | set(em_O.keys())) - rw: # - rarewords increases recall, decreases precision
        if y == 'O' and x in em_O:
            em = em_O[x]
        elif y == 'I-GENE' and x in em_gene:
            em = em_gene[x]
        else:
            em = 0
            '''if y == 'O':
                em = em_O['_RARE_']
            elif y == 'I-GENE':
                em = em_gene['_RARE_']'''
        '''elif x in rarewords:
            if y == 'O':
                em = em_O['_RARE_']
            elif y == 'I-GENE':
                em = em_gene['_RARE_']
        '''
    else:
        if y == 'O':
            em = em_O['_RARE_']
        elif y == 'I-GENE':
            em = em_gene['_RARE_']
    
    return em


def transition_r_mle(g, trigram):        
    ''' trigram tuple elements in {O, I-GENE, *, STOP} '''    
    
    co_3g = g['3g'][trigram]
    co_2g = g['2g'][trigram[:2]]
    
    return co_3g / co_2g


def recursive_vitalg(S,x):
    
    n = len(x)
    
    Sk = [S_1, S0]
    while len(Sk) < n + 2:
        Sk.append(S)
    
    
    def recursive_vpi(k, u, v):
        """
        k = 1,2,3, etc., position in the sentence            
        v = y[k], can not be '*'
        u = y[k - 1]
        
        (k,u,v) possibilities: 
        0,*,*; 
        1,*,y;
        2,y,y;
        """
        
        if (k, u, v) == (0, '*', '*'):
            return {'maxpi': 1, 'wbp': '*'}
        else:
            curpi = 0
            maxpi = 0
            bp = ''
            for w in Sk[(k - 2) + 1]:
                curpi = recursive_vpi(k - 1, w, u)['maxpi'] \
                * transition_r_mle(g,(w, u, v)) \
                * emission_r_mle(em_O, em_gene, x[(k) - 1], v)
                if curpi > maxpi:
                    maxpi = curpi
                    bp = w
            
            return {'maxpi': maxpi, 'wbp': bp}
    
    bp = {} #[[[0 for k in bpl] for j in bpl] for i in range(3)]       
    for k in range(1, n + 1):
        for v in Sk[(k) + 1]:
            for u in Sk[(k - 1) + 1]:
                bp[(k,u,v)] = recursive_vpi(k, u, v)['wbp']
    
    maxpi = 0
    curpi = 0
    y = [0 for i in range(n)]
    for v in Sk[(k) + 1]:
        for u in Sk[(k - 1) + 1]:
            curpi = recursive_vpi(n, u, v)['maxpi'] \
            * transition_r_mle(g, (u, v, 'STOP'))                        
            if curpi > maxpi:
                maxpi = curpi
                y[(n-1) - 1], y[(n) - 1] = u, v  
    
    for k in reversed(range(1, n - 1)):
        y[(k) - 1] = bp[(k + 2, y[(k + 1) - 1], y[(k + 2) -1])]
    
    return y


def viterbi_tagger(inpfu, outfu):
    ''' Viterbi algorithm '''
    
    def table_vitalg(S,x):
        
        
        def table_vpi(S, x):
            """
            k = 1,2,3, etc., position in the sentence            
            v = y[k], can not be '*'
            u = y[k - 1]
            
            (k,u,v) possibilities: 
            0,*,*; 
            1,*,y;
            2,y,y;
            """
            
            htbp = {(0, '*', '*'): '*'} 
            htpi = {(0, '*', '*'): log(1)}
            
            for k in range(1, n + 1):
                for v in Sk[(k) + 1]:
                    for u in Sk[(k - 1) + 1]:
                        curpi = -inf
                        maxpi = -inf
                        bp = ''
                        for w in Sk[(k - 2) + 1]:
                            curpi = htpi[(k - 1, w, u)] \
                            + log(transition_r_mle(g,(w, u, v))) \
                            + log(emission_r_mle(em_O, em_gene, x[(k) - 1], v, tr_rarewords)
                            
                            if curpi > maxpi:
                                maxpi = curpi
                                bp = w
                        
                        htpi[(k, u ,v)] = maxpi
                        htbp[(k, u, v)] = bp
            
            return {'bp': htbp, 'pi': htpi}
        
        
        n = len(x)
        
        Sk = [S_1, S0]
        while len(Sk) < n + 2:
            Sk.append(S)
        
        [piht, bpht] = table_vpi(S, x).values() 
        # for k in reversed(sorted(bpht)):...    print k, bpht[k], piht[k]       
        
        maxpi = log(0)
        curpi = log(0)
        y = [0 for i in range(len(x))]
        for v in Sk[(n) + 1]:
            for u in Sk[(n - 1) + 1]:
                curpi = piht[(n, u, v)] \
                + log(transition_r_mle(g, (u, v, 'STOP')))
                if curpi > maxpi:
                    maxpi = curpi
                    y[(n-1) - 1], y[(n) - 1] = u, v  
        
        for k in reversed(range(1, n - 1)):
            y[(k) - 1] = bpht[(k + 2, y[(k + 1) - 1], y[(k + 2) -1])]
        
        return y
    
    
    inpf = open (inpfu, 'r')    
    outf = open (outfu, 'w')
    
    em_gene = emission_mle(trr_co, y = 'I-GENE')
    em_O = emission_mle(trr_co, y = 'O')
    g = transition_mle(trr_co)
    tr_rarewords = repl_infreq_w(tr_co,)
    
    S_1 = S0 = {'*'}
    S = {'O', 'I-GENE'}
    
    wl = []
    l = inpf.readlines()
    p = 0
    while p < len(l):
        tags = []
        c = 0
        line = []        
        s = l[p + c].strip() 
        while s:
            line.append(s)            
            c += 1
            s = l[p + c].strip()     
        
        p += c + 1
        
        tags = table_vitalg(S,line)
        
        for i in range(len(line)):
            wl = line[i] + ' ' + tags[i] + '\n'            
            outf.write(wl)
        
        outf.write('\n')
    
    inpf.close()
    outf.close()


dp2o = bdir + 'gene_dev.p2.out'
tp2o = bdir + 'gene_test.p2.out'
viterbi_tagger(dev, dp2o)
viterbi_tagger(test, tp2o)
# python eval_gene_tagger.py gene.test gene_test.p2.out
# Submit PART 2: python submit.py




if __name__ == '__main__':
    import sys
    pass
    #some_function(sys.argv[1])




