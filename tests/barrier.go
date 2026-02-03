// create pattern Barrier for golang like python

package main

import (
	"fmt"
	"sync"
	"time"
)

func main() {
	barrier := sync.NewCond(&sync.Mutex{})
	barrier.L.Lock()
	barrier.Wait()
	barrier.L.Unlock()
	fmt.Println("barrier")
}

